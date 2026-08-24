#!/usr/bin/env bash

# Rebuilds everything from scratch into a fresh store.
#
# Usage: bobr-rebuild-world.sh [--local]
#
#   --local   build the bobr binaries from source in this workspace, cloning
#             them from potato if they are not here yet. Without it the run
#             takes the latest published release instead, which is what the
#             Hetzner builder does.
#
# Either way the recipes are pulled first, then the target is realized by one
# real bin/bobr-build.sh invocation into <workspace>/bobr-store.<YYMMDDhhmmss>.
# A preceding dry run of the same driver lowers the unified request used for
# Source seeding and records it for diagnostics.
# Source objects are seeded from the previous store by hardlink, so unchanged
# archives are not downloaded again; all build and reuse mappings start empty.
# Only after the build succeeds is the `bobr-store` symlink repointed at the new
# store. What was built from, and how the host was doing while it built, are
# recorded beside it.

set -euo pipefail

die() {
  echo "bobr-rebuild-world.sh: $*" >&2
  exit 2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required tool not found on PATH: $1"
}

local_mode=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --local) local_mode=1; shift ;;
    -h | --help) sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 0 ;;
    *) die "unexpected argument: $1" ;;
  esac
done

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_repo="$(cd "$(dirname "${script_path}")/.." && pwd)"
workspace_root="$(cd "${recipes_repo}/.." && pwd)"
bobr_repo="${workspace_root}/bobr"
bin_dir="${BOBR_DEV_BIN:-${workspace_root}/bobr-bin/bin}"

# The engine's git URL, used only when this workspace has no checkout yet.
bobr_clone_url="potato:/mnt/git/bobr.git"
bobr_github_api="https://api.github.com/repos/aleksey-makarov/bobr"

[ -d "${recipes_repo}/.git" ] || die "missing git repository: ${recipes_repo}"

require_cmd git
require_cmd jq

echo "==> pull bobr-recipes" >&2
git -C "${recipes_repo}" pull --ff-only

# ---------------------------------------------------------------------------
# the binaries
# ---------------------------------------------------------------------------

# Whatever a run of bobr needs on PATH. Checked explicitly after installing a
# release so a release older than one of them fails here, by name, rather than
# three steps later as "required tool not found".
required_binaries=(bobr fsobj-hash bobr-sandbox-launcher)

# What the binaries were built from, for hashes.txt: a commit either way, so
# that two stores built on different machines can be compared without their
# provenance lines disagreeing over notation.
bobr_revision=""

installed_version() {
  [ -x "${bin_dir}/bobr" ] || return 1
  "${bin_dir}/bobr" --version 2>/dev/null | awk '{print $2}'
}

have_all_binaries() {
  local binary
  for binary in "${required_binaries[@]}"; do
    [ -x "${bin_dir}/${binary}" ] || return 1
  done
}

# Installs one file under its final name only once it is complete, so an
# interrupted run cannot leave a half-written binary behind.
install_binary() {
  local source="$1" name="$2" temp
  temp="${bin_dir}/.${name}.new.$$"
  install -m755 "${source}" "${temp}"
  mv -f "${temp}" "${bin_dir}/${name}"
}

obtain_bobr_from_source() {
  if [ -d "${bobr_repo}/.git" ]; then
    echo "==> pull bobr" >&2
    git -C "${bobr_repo}" pull --ff-only
  else
    echo "==> clone bobr from ${bobr_clone_url}" >&2
    git clone "${bobr_clone_url}" "${bobr_repo}"
  fi

  echo "==> build and install bobr binaries" >&2
  "${bobr_repo}/tools/build-dev.sh" --quick
  bobr_revision="$(git -C "${bobr_repo}" rev-parse HEAD)"
}

obtain_bobr_from_release() {
  require_cmd curl
  require_cmd tar
  require_cmd sha256sum

  local host_target
  case "$(uname -m)" in
    x86_64) host_target="x86_64-unknown-linux-musl" ;;
    *) die "no published bobr archive for $(uname -m); build from source with --local" ;;
  esac

  local latest tag
  latest="$(curl -fsSL "${bobr_github_api}/releases/latest")" \
    || die "cannot reach the GitHub release API"
  tag="$(printf '%s' "${latest}" | jq -r '.tag_name')"
  [ -n "${tag}" ] && [ "${tag}" != "null" ] || die "the latest release has no tag"

  # The commit the tag names. Tags here are annotated, so the ref points at a
  # tag object and has to be dereferenced -- otherwise what lands in hashes.txt
  # is the hash of the tag rather than of the commit it marks.
  local ref object_type object_sha
  ref="$(curl -fsSL "${bobr_github_api}/git/ref/tags/${tag}")" \
    || die "cannot resolve the tag ${tag}"
  object_type="$(printf '%s' "${ref}" | jq -r '.object.type')"
  object_sha="$(printf '%s' "${ref}" | jq -r '.object.sha')"
  if [ "${object_type}" = "tag" ]; then
    object_sha="$(
      curl -fsSL "${bobr_github_api}/git/tags/${object_sha}" | jq -r '.object.sha'
    )" || die "cannot dereference the annotated tag ${tag}"
  fi
  bobr_revision="${object_sha}"

  # Already on it: the point of a release build is the release, and downloading
  # the same one again would only risk replacing working binaries.
  if [ "$(installed_version || true)" = "${tag#v}" ] && have_all_binaries; then
    echo "==> bobr ${tag} is already installed" >&2
    return 0
  fi

  local archive="bobr-${tag}-${host_target}.tar.xz"
  local download="${bobr_github_api%/repos/*}"
  download="https://github.com/aleksey-makarov/bobr/releases/download/${tag}"
  local temp
  temp="$(mktemp -d)"
  # shellcheck disable=SC2064  # the path is fixed at trap time on purpose
  trap "rm -rf '${temp}'" RETURN

  echo "==> download bobr ${tag}" >&2
  curl -fsSL -o "${temp}/${archive}" "${download}/${archive}" \
    || die "cannot download ${archive}"
  curl -fsSL -o "${temp}/SHA256SUMS" "${download}/SHA256SUMS" \
    || die "cannot download SHA256SUMS for ${tag}"
  # Only our own archive's line: the file covers every asset, and the others
  # were not downloaded.
  ( cd "${temp}" && grep -F "${archive}" SHA256SUMS | sha256sum -c --quiet - ) \
    || die "checksum mismatch for ${archive}"

  tar -C "${temp}" -xf "${temp}/${archive}"
  local unpacked="${temp}/bobr-${tag}-${host_target}"
  [ -d "${unpacked}/bin" ] || die "unexpected archive layout in ${archive}"

  # The release replaces whatever was here: mixing binaries from two builds is
  # never wanted, and `bobr` looks for its sandbox launcher beside itself, so
  # the pair has to travel together. Only the default location is cleared --
  # BOBR_DEV_BIN may point at a directory that is not ours to empty.
  if [ -z "${BOBR_DEV_BIN:-}" ]; then
    rm -rf "${workspace_root}/bobr-bin"
  fi
  mkdir -p "${bin_dir}"
  local binary
  for binary in "${unpacked}/bin"/*; do
    install_binary "${binary}" "$(basename "${binary}")"
  done

  for binary in "${required_binaries[@]}"; do
    [ -x "${bin_dir}/${binary}" ] \
      || die "release ${tag} has no ${binary}; publish a newer release or use --local"
  done
  echo "==> installed bobr ${tag} into ${bin_dir}" >&2
}

if [ "${local_mode}" -eq 1 ]; then
  obtain_bobr_from_source
else
  obtain_bobr_from_release
fi

# The binaries were just installed; make sure they are the ones used even if the
# caller has not put the directory on PATH.
export PATH="${bin_dir}:${PATH}"

# ---------------------------------------------------------------------------
# the store
# ---------------------------------------------------------------------------

timetag="$(date '+%y%m%d%H%M%S')"
store_root="${workspace_root}/bobr-store.${timetag}"
store_link="${workspace_root}/bobr-store"
hashes_file="${store_root}/hashes.txt"
request_json="${store_root}/request.json"
script_log="${store_root}/bobr-rebuild-world.log"
host_stats_log="${store_root}/host-stats.log"
profile_path="${store_root}/bobr.ncl"

echo "==> create store ${store_root}" >&2
mkdir "${store_root}"
touch "${script_log}" "${host_stats_log}"

log() {
  local ts
  ts="$(date '+%y%m%d%H%M%S')"
  printf '%s %s\n' "${ts}" "$1" >&2
  printf '%s %s\n' "${ts}" "$1" >> "${script_log}"
}

log_host_snapshot() {
  local label="$1"
  {
    printf '==> %s %s\n' "${label}" "$(date '+%y%m%d%H%M%S')"
    printf 'loadavg '
    cat /proc/loadavg
    printf 'nproc %s\n' "$(nproc)"
    awk '
      /^(MemTotal|MemFree|MemAvailable|Buffers|Cached|Dirty|Writeback):/ {
        print "meminfo " $0
      }
    ' /proc/meminfo
    [ -r /proc/pressure/cpu ] && sed 's/^/pressure_cpu /' /proc/pressure/cpu
    [ -r /proc/pressure/io ] && sed 's/^/pressure_io /' /proc/pressure/io
    df -h "${store_root}" | sed 's/^/df /'
    printf '\n'
  } >> "${host_stats_log}"
}

# The profile is the shipped example with its store pointed at the one just
# made: a rebuild should go through the same settings a reader of the recipes
# would get, not through a private two-line file that could drift from them.
cp "${recipes_repo}/bobr.ncl.example" "${profile_path}"
sed -i "s|^  store = \".*\",\$|  store = \"${store_root}\",|" "${profile_path}"
grep -Fq "  store = \"${store_root}\"," "${profile_path}" \
  || die "could not point the profile at the store; has bobr.ncl.example changed shape?"

git_head() { git -C "$1" rev-parse HEAD 2>/dev/null || echo unknown; }
{
  printf 'bobr %s\n' "${bobr_revision:-unknown}"
  printf 'bobr-recipes %s\n' "$(git_head "${recipes_repo}")"
} > "${hashes_file}"

log "store=${store_root}"
log "mode=$([ "${local_mode}" -eq 1 ] && echo local || echo release)"
log "bobr=${bobr_revision:-unknown}"
log_host_snapshot "after-store-create"

# bobr-build.sh prints its lowering and realization timings to stderr; pointing
# it at the run log records them there too.
export BOBR_BUILD_TIMING_LOG="${script_log}"

# ---------------------------------------------------------------------------
# seeding
# ---------------------------------------------------------------------------

# Export the unified request once to learn which Source objects to seed. It
# doubles as an early failure if the recipes do not lower.
echo "==> export build request" >&2
"${recipes_repo}/bin/bobr-build.sh" "${profile_path}" --dry-run \
  > "${request_json}" 2>>"${script_log}"

# Hardlink one object (file or directory) into the new store, atomically and only
# if absent. `cp -al` recurses, so directory objects (e.g. OCI layouts) work too.
copy_seed_object() {
  local source_object="$1" target_object="$2"
  local temp_object="${target_object}.seed.$$"
  if [ -e "${target_object}" ] || [ -L "${target_object}" ]; then
    return 0
  fi
  rm -rf "${temp_object}"
  if ! cp -al -- "${source_object}" "${temp_object}"; then
    rm -rf "${temp_object}"
    return 1
  fi
  if ! mv -T -- "${temp_object}" "${target_object}"; then
    rm -rf "${temp_object}"
    return 1
  fi
}

# Latest timestamped store other than the current one (lexicographic order works
# for the zero-padded timestamps).
find_previous_store() {
  local candidate previous=""
  shopt -s nullglob
  for candidate in "${workspace_root}"/bobr-store.*; do
    [ -d "${candidate}" ] || continue
    [ "${candidate}" = "${store_root}" ] && continue
    [[ "$(basename "${candidate}")" =~ ^bobr-store\.[0-9]{12}$ ]] || continue
    if [ -z "${previous}" ] \
      || [[ "$(basename "${candidate}")" > "$(basename "${previous}")" ]]; then
      previous="${candidate}"
    fi
  done
  shopt -u nullglob
  printf '%s\n' "${previous}"
}

# This deliberately seeds Source content only. Configuring the previous store
# as a general secondary would also reuse its build results and the rebuild
# would no longer be cold.
seed_source_objects() {
  local previous_store="$1"
  local object_hash source_object target_object
  local total=0 linked=0 already=0 missing=0

  if [ -z "${previous_store}" ]; then
    log "seed: no previous store found"
    return 0
  fi

  log "seed source objects from ${previous_store}"
  mkdir -p "${store_root}/objects"
  while IFS= read -r object_hash; do
    [ -n "${object_hash}" ] || continue
    total=$((total + 1))
    source_object="${previous_store}/objects/${object_hash}"
    target_object="${store_root}/objects/${object_hash}"
    if [ -e "${target_object}" ] || [ -L "${target_object}" ]; then
      already=$((already + 1))
      continue
    fi
    if [ ! -e "${source_object}" ] && [ ! -L "${source_object}" ]; then
      missing=$((missing + 1))
      continue
    fi
    copy_seed_object "${source_object}" "${target_object}"
    linked=$((linked + 1))
  done < <(
    # Trimmed in jq rather than after it: a RecipePath source declares its hash
    # from a lock file imported as text, so the value carries the file's
    # trailing newline and would otherwise arrive as two lines.
    jq -r \
      '.nodes[] | select(.tag == "Source") | .object_hash | gsub("\\s"; "")' \
      "${request_json}" | sort -u
  )
  log "seed: total=${total} linked=${linked} already=${already} missing=${missing}"
}

previous_store="$(find_previous_store)"
log "previous_store=${previous_store:-none}"
log_host_snapshot "before-seed"
seed_started_at="$(date '+%s')"
seed_source_objects "${previous_store}"
log "seed_seconds=$(( $(date '+%s') - seed_started_at ))"
log_host_snapshot "after-seed"

# ---------------------------------------------------------------------------
# realization
# ---------------------------------------------------------------------------

# Runs one phase under `time` when it is available, recording its resource use
# next to the timings the drivers report themselves.
run_phase() {
  local label="$1"
  shift
  local time_bin time_report status=0
  time_bin="$(type -P time || true)"
  time_report="$(mktemp)"
  if [ -n "${time_bin}" ]; then
    "${time_bin}" -o "${time_report}" \
      -f "==> ${label} time: real %e s, user %U s, sys %S s, maxrss %M KB" \
      "$@" || status=$?
  else
    "$@" || status=$?
  fi
  if [ -s "${time_report}" ]; then
    tee -a "${script_log}" < "${time_report}" >&2
  fi
  rm -f "${time_report}"
  return "${status}"
}

echo "==> realize world" >&2
log_host_snapshot "before-realize"
realize_started_at="$(date '+%s')"
realize_status=0
run_phase realize \
  "${recipes_repo}/bin/bobr-build.sh" "${profile_path}" || realize_status=$?
log "realize_seconds=$(( $(date '+%s') - realize_started_at ))"
[ "${realize_status}" -eq 0 ] || exit "${realize_status}"
log_host_snapshot "after-realize"

# The build succeeded: repoint the convenience symlink at the new store.
# Overwrite an existing symlink; leave any non-symlink of that name untouched.
if [ -L "${store_link}" ] || [ ! -e "${store_link}" ]; then
  ln -sfnT "$(basename "${store_root}")" "${store_link}"
  echo "==> link: ${store_link} -> $(basename "${store_root}")" >&2
fi

echo "==> store: ${store_root}" >&2
echo "==> profile: ${profile_path}" >&2
echo "==> hashes: ${hashes_file}" >&2
echo "==> request: ${request_json}" >&2
echo "==> script log: ${script_log}" >&2
echo "==> host stats: ${host_stats_log}" >&2
