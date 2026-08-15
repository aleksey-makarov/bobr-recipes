#!/usr/bin/env bash

# Builds one recipe from these recipes, as described by a build profile.
#
# Usage:
#   bobr-build.sh [OPTIONS] [PROFILE.ncl]
#
#   PROFILE.ncl              the build profile (default: ./bobr.ncl); start from
#                            <recipes>/bobr.ncl.example
#   --target NAME            build this recipe instead of the profile's
#   --jobs N | -j N          cap builders running at once
#   --quiet                  keep only warnings and errors on screen
#   --dry-run                print the resolved profile and the JSON request,
#                            build nothing
#   -h | --help              show this help
#
# The profile says where to build and what; this run's name and its log and work
# directories are minted here, per invocation. `bobr` and `fsobj-hash` come from
# PATH -- install a release, or use the engine's tools/build-dev.sh to build them
# from a source checkout first.

set -euo pipefail

usage() {
  sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"
tool="bobr-build.sh"
# shellcheck source=bin/profile-lib.sh
. "${recipes_path}/bin/profile-lib.sh"

profile_path=""
target=""
jobs=""
quiet=""
dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      target="$2"
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
    --dry-run)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --*)
      die "unknown option: $1"
      ;;
    *)
      [ -z "${profile_path}" ] || die "unexpected argument: $1"
      profile_path="$1"
      shift
      ;;
  esac
done

[ -n "${profile_path}" ] || profile_path="bobr.ncl"
profile_given="${profile_path}"
profile_path="$(realpath -e -- "${profile_given}" 2>/dev/null)" \
  || die "no build profile at '${profile_given}'; copy ${recipes_path}/bobr.ncl.example to ./bobr.ncl"

if [ -n "${jobs}" ] && ! [[ "${jobs}" =~ ^[1-9][0-9]*$ ]]; then
  die "--jobs must be a positive integer"
fi
if [ -n "${target}" ] && ! [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  die "invalid recipe attribute name: ${target}"
fi

require_cmd nickel
require_cmd bobr
require_cmd fsobj-hash

resolve_profile "${profile_path}"

store_path="${profile_store}"
logs_root="${profile_logs}"
work_root="${profile_work}"
overlays_expr="${profile_overlays}"
[ -n "${target}" ] || target="${profile_target}"
[ -n "${jobs}" ] || { [ "${profile_jobs}" = "0" ] || jobs="${profile_jobs}"; }
[ -n "${quiet}" ] || quiet="${profile_quiet}"
podman_unshare="${profile_podman_unshare}"

[ -n "${target}" ] \
  || die "no recipe to build: set 'target' in ${profile_path} or pass --target NAME"
[ -d "${store_path}" ] \
  || die "store does not exist: ${store_path} (create it: mkdir -p '${store_path}')"

check_request_schema "${recipes_path}/request-schema.ncl" bobr

# Local sources are pinned by a lock file next to them. A stale lock would build
# the old content silently, so refuse rather than write into the recipes tree --
# the caller edited it and should say so. bin/bobr-update-fsobj-hashes.sh refreshes
# them for recipe work.
"${recipes_path}/bin/bobr-update-fsobj-hashes.sh" --check \
  || die "recipe hash locks are stale; refresh them: ${recipes_path}/bin/bobr-update-fsobj-hashes.sh"


if [ "${dry_run}" -eq 1 ]; then
  # A dry run creates nothing: it names the directories a real build would have
  # made and stops after lowering.
  run_id="$(date '+%y%m%d%H%M%S')"
else
  mkdir -p "${logs_root}" "${work_root}"
  run_id="$(allocate_run_id "${logs_root}" "${work_root}")"
fi
logs_path="${logs_root}/${run_id}"
work_path="${work_root}/${run_id}"

merge_fields=()
[ -n "${jobs}" ] && merge_fields+=("jobs = ${jobs}")
[ "${quiet}" -eq 1 ] && merge_fields+=("quiet = true")
merge_expr=""
if [ "${#merge_fields[@]}" -gt 0 ]; then
  merge_expr=" & { $(IFS=,; echo "${merge_fields[*]}") }"
fi

request_expr="(import \"${recipes_path}/request.ncl\") {
  store_path = \"${store_path}\",
  logs_path = \"${logs_path}\",
  work_path = \"${work_path}\",
  run_id = \"${run_id}\",
  recipes_path = \"${recipes_path}\",
  target_name = \"${target}\",
  overlays = ${overlays_expr},
}${merge_expr}"


if [ "${dry_run}" -eq 1 ]; then
  {
    echo "==> profile ${profile_path} resolves to:"
    printf '%s\n' "${profile_resolved}" | sed 's/^profile_/  /'
    echo "==> target: ${target}"
    echo "==> ${tool_version}"
  } >&2
  nickel_started_at="$(date +%s.%N)"
  printf '%s\n' "${request_expr}" | nickel export --format json
  nickel_finished_at="$(date +%s.%N)"
  report_phase_time "nickel recipes -> json request" \
    "${nickel_started_at}" "${nickel_finished_at}"
  exit 0
fi

bobr_cmd=(bobr)
if [ "${podman_unshare}" -eq 1 ]; then
  bobr_cmd=(podman unshare bobr)
  require_cmd podman
fi

# Export the request to a file first -- timed on its own -- rather than piping
# nickel straight into bobr, so the recipes -> JSON pass and the build itself are
# measured and reported separately.
request_json="$(mktemp)"
trap 'rm -f "${request_json}"' EXIT
nickel_started_at="$(date +%s.%N)"
printf '%s\n' "${request_expr}" | nickel export --format json > "${request_json}"
nickel_finished_at="$(date +%s.%N)"
report_phase_time "nickel recipes -> json request" \
  "${nickel_started_at}" "${nickel_finished_at}"

bobr_started_at="$(date +%s.%N)"
bobr_status=0
"${bobr_cmd[@]}" < "${request_json}" || bobr_status="$?"
bobr_finished_at="$(date +%s.%N)"
report_phase_time "bobr build" "${bobr_started_at}" "${bobr_finished_at}"
exit "${bobr_status}"
