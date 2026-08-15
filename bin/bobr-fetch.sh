#!/usr/bin/env bash

# Downloads one recipe's sources into the store, as described by a build
# profile. Run it before bin/bobr-build.sh and the build finds every source
# already present, doing no recipe-driven network work of its own.
#
# Usage:
#   bobr-fetch.sh [OPTIONS] [PROFILE.ncl]
#
#   PROFILE.ncl              the build profile (default: ./bobr.ncl); the same
#                            file bin/bobr-build.sh reads
#   --target NAME            fetch for this recipe instead of the profile's
#   --quiet                  keep only warnings and errors on screen
#   --dry-run                print the resolved profile and the JSON request,
#                            fetch nothing
#   -h | --help              show this help
#
# The profile says where the store is and what to fetch; this run's name and
# its log and work directories are minted here, per invocation. `bobr-fetch`
# comes from PATH -- install a release, or use the engine's tools/build-dev.sh
# to build it from a source checkout first.

set -euo pipefail

usage() {
  sed -n '3,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"
tool="bobr-fetch.sh"
# shellcheck source=bin/profile-lib.sh
. "${recipes_path}/bin/profile-lib.sh"

profile_path=""
target=""
quiet=""
dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      target="$2"
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

if [ -n "${target}" ] && ! [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  die "invalid recipe attribute name: ${target}"
fi

require_cmd nickel
require_cmd bobr-fetch

resolve_profile "${profile_path}"

store_path="${profile_store}"
logs_root="${profile_logs}"
work_root="${profile_work}"
overlays_expr="${profile_overlays}"
[ -n "${target}" ] || target="${profile_target}"
[ -n "${quiet}" ] || quiet="${profile_quiet}"

[ -n "${target}" ] \
  || die "no recipe to fetch for: set 'target' in ${profile_path} or pass --target NAME"
[ -d "${store_path}" ] \
  || die "store does not exist: ${store_path} (create it: mkdir -p '${store_path}')"

# Two things the build wrapper does and this one deliberately does not:
#
# * the recipe hash-lock check. A stale lock misdeclares a RecipePath source,
#   and those are left to the build. When they move here this needs revisiting
#   -- and the answer will not be to copy the check over: the fetcher skips a
#   source whose declared hash is already an object in the store, which a stale
#   lock's usually is, so the staleness would pass unseen. Hash the local file
#   every run instead, and let the mismatch report the real value.
# * `podman unshare`. The fetcher creates no namespaces: it downloads, and
#   imports by renaming and hardlinking files it made itself.
check_request_schema "${recipes_path}/fetch-request-schema.ncl" bobr-fetch


if [ "${dry_run}" -eq 1 ]; then
  # A dry run creates nothing: it names the directories a real run would have
  # made and stops after lowering.
  run_id="$(date '+%y%m%d%H%M%S')"
else
  mkdir -p "${logs_root}" "${work_root}"
  run_id="$(allocate_run_id "${logs_root}" "${work_root}")"
fi
logs_path="${logs_root}/${run_id}"
work_path="${work_root}/${run_id}"

merge_expr=""
[ "${quiet}" -eq 1 ] && merge_expr=" & { quiet = true }"

request_expr="(import \"${recipes_path}/request-fetch.ncl\") {
  store_path = \"${store_path}\",
  logs_path = \"${logs_path}\",
  work_path = \"${work_path}\",
  run_id = \"${run_id}\",
  recipes_path = \"${recipes_path}\",
  target_name = \"${target}\",
  overlays = ${overlays_expr},
  fetch = ${profile_fetch},
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
  report_phase_time "nickel recipes -> json fetch request" \
    "${nickel_started_at}" "${nickel_finished_at}"
  exit 0
fi

# Exported to a file first -- timed on its own -- rather than piped straight
# into the fetcher, so lowering and downloading are measured separately: the
# lowering walks the same graph the build does and takes about as long, while
# the downloading is minutes.
request_json="$(mktemp)"
trap 'rm -f "${request_json}"' EXIT
nickel_started_at="$(date +%s.%N)"
printf '%s\n' "${request_expr}" | nickel export --format json > "${request_json}"
nickel_finished_at="$(date +%s.%N)"
report_phase_time "nickel recipes -> json fetch request" \
  "${nickel_started_at}" "${nickel_finished_at}"

fetch_started_at="$(date +%s.%N)"
fetch_status=0
bobr-fetch "${request_json}" || fetch_status="$?"
fetch_finished_at="$(date +%s.%N)"
report_phase_time "bobr fetch" "${fetch_started_at}" "${fetch_finished_at}"
exit "${fetch_status}"
