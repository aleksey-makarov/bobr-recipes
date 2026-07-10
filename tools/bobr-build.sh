#!/usr/bin/env bash

# Build one bobr-recipes package attribute and run it through `bobr`.
#
# The driver refreshes local `*.fsobj-hash` locks, builds the JSON request for
# one `pkgs.ncl` attribute through `request.ncl` (with optional overlays and
# quiet/jobs), and pipes it into `bobr`.
#
# Usage:
#   bobr-build.sh [OPTIONS] <pkgs-attr>
#
#   --store PATH             store root, absolute (default: <recipes-path>/../bobr-store)
#   --recipes-path PATH      recipes checkout (default: this script's repo)
#   --overlays FILE          a file evaluating to an array of overlays (repeatable)
#   --overlay FILE           a file evaluating to a single overlay (repeatable)
#   --jobs N | -j N          cap parallel builder execution
#   --quiet                  suppress the live progress log
#   --podman-unshare         run bobr under `podman unshare`
#   --bobr PATH              explicit bobr binary
#   --dry-run | --export-only   print the JSON request and do not run bobr
#   -h | --help              show this help

set -euo pipefail

die() {
  echo "bobr-build.sh: $*" >&2
  exit 2
}

usage() {
  sed -n '3,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required tool not found: $1"
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
driver_repo="$(cd "$(dirname "${script_path}")/.." && pwd)"
workspace_root="$(cd "${driver_repo}/.." && pwd)"

recipes_path="${driver_repo}"
store_path=""
jobs=""
quiet=0
podman_unshare=0
dry_run=0
bobr_override=""
overlays_expr="[]"
bobr_from_dev=0
bobr_profile=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --store)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      store_path="$2"
      shift 2
      ;;
    --recipes-path)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      recipes_path="$2"
      shift 2
      ;;
    --overlays)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      overlay_file="$(realpath -e -- "$2")"
      overlays_expr="${overlays_expr} @ (import \"${overlay_file}\")"
      shift 2
      ;;
    --overlay)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      overlay_file="$(realpath -e -- "$2")"
      overlays_expr="${overlays_expr} @ [import \"${overlay_file}\"]"
      shift 2
      ;;
    --jobs | -j)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      jobs="$2"
      shift 2
      ;;
    --quiet)
      quiet=1
      shift
      ;;
    --podman-unshare)
      podman_unshare=1
      shift
      ;;
    --bobr)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      bobr_override="$2"
      shift 2
      ;;
    --dry-run | --export-only)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

[ "$#" -eq 1 ] || { usage; exit 2; }
attr="$1"

recipes_path="$(realpath -e -- "${recipes_path}")" || die "--recipes-path does not exist"
[ -f "${recipes_path}/request.ncl" ] || die "no request.ncl under --recipes-path: ${recipes_path}"

# Default the store to <recipes-path>/../bobr-store when --store is omitted.
if [ -z "${store_path}" ]; then
  store_path="$(realpath -ms -- "${recipes_path}/../bobr-store")"
fi
case "${store_path}" in
  /*) ;;
  *) die "store path must be absolute: ${store_path}" ;;
esac
[[ "${attr}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid pkgs attribute name: ${attr}"
if [ -n "${jobs}" ] && ! [[ "${jobs}" =~ ^[1-9][0-9]*$ ]]; then
  die "--jobs must be a positive integer"
fi

# Resolve bobr: explicit override, then the sibling dev build tree (release
# preferred over debug), then an installed binary on PATH.
if [ -n "${bobr_override}" ]; then
  bobr_bin="${bobr_override}"
else
  bobr_bin=""
  for profile in release debug; do
    candidate="${workspace_root}/bobr/target/${profile}/bobr"
    if [ -x "${candidate}" ]; then
      bobr_bin="${candidate}"
      bobr_from_dev=1
      bobr_profile="${profile}"
      break
    fi
  done
  if [ -z "${bobr_bin}" ]; then
    bobr_bin="$(command -v bobr || true)"
  fi
fi

# fsobj-hash lives next to the resolved bobr, or on PATH.
fsobj_hash_bin=""
if [ -n "${bobr_bin}" ] && [ -x "$(dirname "${bobr_bin}")/fsobj-hash" ]; then
  fsobj_hash_bin="$(dirname "${bobr_bin}")/fsobj-hash"
else
  fsobj_hash_bin="$(command -v fsobj-hash || true)"
fi

# Hard dependency checks. `nickel` and `fsobj-hash` are always needed (the
# request export and the hash refresh); the runtime tools only when we actually
# run bobr.
require_cmd nickel
[ -n "${fsobj_hash_bin}" ] || die "fsobj-hash not found (next to bobr or on PATH); build it with: cargo build -p fsobj-hash"

if [ "${dry_run}" -eq 0 ]; then
  { [ -n "${bobr_bin}" ] && [ -x "${bobr_bin}" ]; } || die "bobr binary not found; build it or pass --bobr"
  require_cmd mkfs.erofs
  require_cmd newuidmap
  require_cmd newgidmap
  if [ "${podman_unshare}" -eq 1 ]; then
    require_cmd podman
  fi
  if [ "${bobr_from_dev}" -eq 1 ]; then
    launcher="${workspace_root}/bobr/target/x86_64-unknown-linux-musl/${bobr_profile}/bobr-sandbox-launcher"
    [ -x "${launcher}" ] || die "sandbox launcher not built: ${launcher}
build it with: (cd ${workspace_root}/bobr && cargo build-sandbox-launcher)"
  fi
fi

# Refresh local *.fsobj-hash locks in the recipes checkout being built.
"${recipes_path}/tools/bobr-update-fsobj-hashes.sh" --fsobj-hash="${fsobj_hash_bin}"

# request.ncl returns { schema, store, nodes }; quiet/jobs are merged on top.
merge_fields=()
[ -n "${jobs}" ] && merge_fields+=("jobs = ${jobs}")
[ "${quiet}" -eq 1 ] && merge_fields+=("quiet = true")

request_expr="let request = import \"${recipes_path}/request.ncl\" in
let base = request {
  store_path = \"${store_path}\",
  recipes_path = \"${recipes_path}\",
  target_name = \"${attr}\",
  overlays = ${overlays_expr},
} in"
if [ "${#merge_fields[@]}" -gt 0 ]; then
  merge_joined="$(IFS=,; echo "${merge_fields[*]}")"
  request_expr="${request_expr}
base & { ${merge_joined} }"
else
  request_expr="${request_expr}
base"
fi

# Print the wall time of one `nickel recipes -> JSON request` pass to stderr.
report_nickel_time() {
  awk -v s="$1" -v e="$2" \
    'BEGIN { printf "==> nickel recipes -> json request: %.2fs\n", e - s }' >&2
}

if [ "${dry_run}" -eq 1 ]; then
  nickel_started_at="$(date +%s.%N)"
  printf '%s\n' "${request_expr}" | nickel export --format json
  nickel_finished_at="$(date +%s.%N)"
  report_nickel_time "${nickel_started_at}" "${nickel_finished_at}"
  exit 0
fi

mkdir -p "${store_path}"

bobr_cmd=("${bobr_bin}")
if [ "${podman_unshare}" -eq 1 ]; then
  bobr_cmd=(podman unshare "${bobr_bin}")
fi

# Export the request to a file first -- timed on its own -- rather than piping
# nickel straight into bobr, so the recipes -> JSON pass is measured separately
# from the build that follows.
request_json="$(mktemp)"
trap 'rm -f "${request_json}"' EXIT
nickel_started_at="$(date +%s.%N)"
printf '%s\n' "${request_expr}" | nickel export --format json > "${request_json}"
nickel_finished_at="$(date +%s.%N)"
report_nickel_time "${nickel_started_at}" "${nickel_finished_at}"
"${bobr_cmd[@]}" < "${request_json}"
