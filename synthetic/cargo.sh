#!/usr/bin/env bash
# Cargo build script for the SandboxInstall builder: installs the built binaries
# into the live read-write overlay root (/usr/bin) rather than into a staging
# $out. The build's additions become the captured fs-tree layer.
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
step="${1:-${BOBR_STEP_NAME:-}}"
step="${step:?step name is required}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
build_workspace_dir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}"
synthetic_common="${BOBR_SYNTHETIC_COMMON:?BOBR_SYNTHETIC_COMMON is required}"
crates_dir="${BOBR_CRATES_DIR:?BOBR_CRATES_DIR is required}"

. "$synthetic_common"

# Where `cargo build`/CARGO_HOME/config live, and where `cargo install` stages
# the binaries (build-user-writable, so compilation never runs as root).
cargo_home="${build_workspace_dir}/.cargo"
vendor_dir="${build_workspace_dir}/vendor"
stage_dir="${build_workspace_dir}/stage"

load_env_files() {
  if [ -d "${cfg}/env" ]; then
    while IFS= read -r -d '' path; do
      export "$(basename "$path")=$(cat "$path")"
    done < <(find "${cfg}/env" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
  fi
}

append_dir_files_to_array() {
  local dir="$1"
  local array_name="$2"
  local -n result_ref="$array_name"
  if [ -d "$dir" ]; then
    while IFS= read -r -d '' path; do
      result_ref+=("$(cat "$path")")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z)
  fi
}

resolve_project_source_dir() {
  local source_subdir=""
  if [ ! -d "$source_dir" ]; then
    echo "cargo build-script: source input is not a directory: ${source_dir}" >&2
    exit 1
  fi
  if [ -f "${cfg}/source_subdir" ]; then
    source_subdir="$(cat "${cfg}/source_subdir")"
    case "$source_subdir" in
      ""|/*|*"/../"*|../*|*"./"*|*"/.."|"..")
        echo "cargo build-script: invalid source_subdir '${source_subdir}'" >&2
        exit 1
        ;;
    esac
  fi
  local project_source_dir="$source_dir"
  if [ -n "$source_subdir" ]; then
    project_source_dir="${source_dir}/${source_subdir}"
  fi
  if [ ! -f "${project_source_dir}/Cargo.toml" ]; then
    echo "cargo build-script: Cargo.toml not found in ${project_source_dir}" >&2
    exit 1
  fi
  printf '%s\n' "$project_source_dir"
}

setup_cargo_env() {
  export CARGO_HOME="$cargo_home"
  export HOME="$build_workspace_dir"
  # The build rootfs carries gcc/binutils but not necessarily a `cc` alias;
  # rustc defaults to `cc` as the linker driver, so pin it to gcc.
  export CC=gcc
  export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc
}

# Unpack each vendored `.crate` into a cargo `vendor/` tree and point cargo at it
# offline. A crate's cargo checksum is the sha256 of its `.crate` file.
step_vendor() {
  mkdir -p "$vendor_dir"
  local crate tmp top sha
  for crate in "$crates_dir"/*; do
    [ -e "$crate" ] || continue
    tmp="$(mktemp -d)"
    tar -C "$tmp" -xf "$crate"
    top="$(ls "$tmp")"
    mv "$tmp/$top" "$vendor_dir/$top"
    rmdir "$tmp"
    sha="$(sha256sum "$crate" | cut -d' ' -f1)"
    printf '{"files":{},"package":"%s"}' "$sha" > "$vendor_dir/$top/.cargo-checksum.json"
  done
  mkdir -p "$cargo_home"
  cat > "${cargo_home}/config.toml" <<EOF
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "${vendor_dir}"

[net]
offline = true
EOF
}

# `cargo install` builds (release) and installs the crate's [[bin]] targets into
# <root>/bin. Stage under the build workspace so this runs as build-user, then
# the install step copies into the live root as root.
step_build() {
  local project_source_dir
  local extra_args=()
  local features=() bins=()
  project_source_dir="$(resolve_project_source_dir)"
  setup_cargo_env

  append_dir_files_to_array "${cfg}/features" features
  append_dir_files_to_array "${cfg}/bins" bins
  if [ "${#features[@]}" -gt 0 ]; then
    local joined
    joined="$(IFS=,; echo "${features[*]}")"
    extra_args+=("--features" "$joined")
  fi
  if [ -f "${cfg}/no_default_features" ]; then
    extra_args+=("--no-default-features")
  fi
  local bin
  for bin in "${bins[@]}"; do
    extra_args+=("--bin" "$bin")
  done

  cargo install \
    --path "$project_source_dir" \
    --root "$stage_dir" \
    --offline \
    --locked \
    "${extra_args[@]}"
}

step_install() {
  # Install the staged binaries into the live overlay root as root:root; the
  # writes land in the overlay upper layer and become the captured fs-tree.
  # (Do NOT chown -R /usr -- that would copy up and modify the whole tree.)
  if [ -d "${stage_dir}/bin" ]; then
    local f
    for f in "${stage_dir}/bin/"*; do
      [ -e "$f" ] || continue
      install -Dm755 "$f" "/usr/bin/$(basename "$f")"
    done
  fi
}

load_env_files
bobr_prepare_source

case "$step" in
  prepare) : ;;
  vendor) step_vendor ;;
  build) step_build ;;
  install) step_install ;;
  *)
    echo "cargo build-script: unsupported step '$step'" >&2
    exit 1
    ;;
esac
