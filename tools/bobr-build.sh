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
#   --logs PATH              run log root, absolute (default: <store>/logs)
#   --work PATH              run work root, absolute (default: <store>/work); must
#                            be on the store's filesystem
#   --run-id NAME            name this run (default: the local timestamp, with
#                            .1, .2, ... appended if that one is taken)
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
logs_root=""
work_root=""
run_id=""
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
    --logs)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      logs_root="$2"
      shift 2
      ;;
    --work)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      work_root="$2"
      shift 2
      ;;
    --run-id)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      run_id="$2"
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

# `bobr` is given a ready-made pair of directories for the run and the name to
# record it under; picking the name and creating them is the caller's job, and
# that is what keeps two concurrent runs apart. Default them inside the store,
# which also puts the work directory on the store's filesystem -- the store
# publishes build output by renaming and hardlinking out of it.
[ -n "${logs_root}" ] || logs_root="${store_path}/logs"
[ -n "${work_root}" ] || work_root="${store_path}/work"
for root in "${logs_root}" "${work_root}"; do
  case "${root}" in
    /*) ;;
    *) die "run directory root must be absolute: ${root}" ;;
  esac
done
if [ -n "${run_id}" ] && ! [[ "${run_id}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  die "--run-id must start with a letter or digit and may contain only letters, digits, '.', '_', and '-'"
fi

# Claims one run: `mkdir` fails rather than reuses, so a name taken by another
# run (or a previous one) is skipped instead of shared.
allocate_run_id() {
  local base attempt candidate
  base="$(date '+%y%m%d%H%M%S')"
  for attempt in $(seq 0 999); do
    if [ "${attempt}" -eq 0 ]; then
      candidate="${base}"
    else
      candidate="${base}.${attempt}"
    fi
    if mkdir "${logs_root}/${candidate}" 2>/dev/null; then
      if mkdir "${work_root}/${candidate}" 2>/dev/null; then
        printf '%s\n' "${candidate}"
        return 0
      fi
      rmdir "${logs_root}/${candidate}"
    fi
  done
  die "failed to allocate a unique run id under ${logs_root}"
}
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
  require_cmd newuidmap
  require_cmd newgidmap
  if [ "${podman_unshare}" -eq 1 ]; then
    require_cmd podman
  fi
  if [ "${bobr_from_dev}" -eq 1 ]; then
    case "$(uname -m)" in
      x86_64) host_musl_target="x86_64-unknown-linux-musl" ;;
      aarch64) host_musl_target="aarch64-unknown-linux-musl" ;;
      *) die "unsupported host architecture for the sandbox launcher: $(uname -m)" ;;
    esac
    launcher="${workspace_root}/bobr/target/${host_musl_target}/${bobr_profile}/bobr-sandbox-launcher"
    [ -x "${launcher}" ] || die "sandbox launcher not built: ${launcher}
build it with: (cd ${workspace_root}/bobr && cargo build-sandbox-launcher-${host_musl_target%%-*})"
  fi
fi

# Refresh local *.fsobj-hash locks in the recipes checkout being built.
"${recipes_path}/tools/bobr-update-fsobj-hashes.sh" --fsobj-hash="${fsobj_hash_bin}"

# A dry run only lowers the request, so it creates nothing: the run directories
# it names are the ones a real build would have made.
if [ "${dry_run}" -eq 1 ]; then
  [ -n "${run_id}" ] || run_id="$(date '+%y%m%d%H%M%S')"
else
  mkdir -p "${store_path}" "${logs_root}" "${work_root}"
  if [ -n "${run_id}" ]; then
    mkdir "${logs_root}/${run_id}" \
      || die "run log directory already exists: ${logs_root}/${run_id}"
    mkdir "${work_root}/${run_id}" \
      || die "run work directory already exists: ${work_root}/${run_id}"
  else
    run_id="$(allocate_run_id)"
  fi
fi
logs_path="${logs_root}/${run_id}"
work_path="${work_root}/${run_id}"

# request.ncl returns { schema, store, logs, work, run_id, nodes }; quiet/jobs
# are merged on top.
merge_fields=()
[ -n "${jobs}" ] && merge_fields+=("jobs = ${jobs}")
[ "${quiet}" -eq 1 ] && merge_fields+=("quiet = true")

request_expr="let request = import \"${recipes_path}/request.ncl\" in
let base = request {
  store_path = \"${store_path}\",
  logs_path = \"${logs_path}\",
  work_path = \"${work_path}\",
  run_id = \"${run_id}\",
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

# Print the wall time of one build phase ("nickel recipes -> json request" or
# "bobr build") to stderr. When BOBR_BUILD_TIMING_LOG names a file, append the
# same line there too -- that lets callers such as bobr-rebuild-world.sh record
# the split without teeing bobr's live progress UI off stderr.
report_phase_time() {
  local label="$1" start="$2" end="$3" line
  line="$(awk -v l="${label}" -v s="${start}" -v e="${end}" \
    'BEGIN { printf "==> %s: %.2fs", l, e - s }')"
  printf '%s\n' "${line}" >&2
  if [ -n "${BOBR_BUILD_TIMING_LOG:-}" ]; then
    printf '%s\n' "${line}" >> "${BOBR_BUILD_TIMING_LOG}"
  fi
}

if [ "${dry_run}" -eq 1 ]; then
  nickel_started_at="$(date +%s.%N)"
  printf '%s\n' "${request_expr}" | nickel export --format json
  nickel_finished_at="$(date +%s.%N)"
  report_phase_time "nickel recipes -> json request" \
    "${nickel_started_at}" "${nickel_finished_at}"
  exit 0
fi

bobr_cmd=("${bobr_bin}")
if [ "${podman_unshare}" -eq 1 ]; then
  bobr_cmd=(podman unshare "${bobr_bin}")
fi

# Export the request to a file first -- timed on its own -- rather than piping
# nickel straight into bobr, so the recipes -> JSON pass and the build itself
# are measured and reported separately.
request_json="$(mktemp)"
trap 'rm -f "${request_json}"' EXIT
nickel_started_at="$(date +%s.%N)"
printf '%s\n' "${request_expr}" | nickel export --format json > "${request_json}"
nickel_finished_at="$(date +%s.%N)"
report_phase_time "nickel recipes -> json request" \
  "${nickel_started_at}" "${nickel_finished_at}"

# Time the bobr build separately, preserving its exit status.
bobr_started_at="$(date +%s.%N)"
bobr_status=0
"${bobr_cmd[@]}" < "${request_json}" || bobr_status="$?"
bobr_finished_at="$(date +%s.%N)"
report_phase_time "bobr build" "${bobr_started_at}" "${bobr_finished_at}"
exit "${bobr_status}"
