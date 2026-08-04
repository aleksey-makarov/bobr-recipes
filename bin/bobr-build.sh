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
# PATH -- install a release, or use tools/dev/bobr-build-dev.sh to build them
# from a source checkout first.

set -euo pipefail

die() {
  echo "bobr-build.sh: $*" >&2
  exit 2
}

usage() {
  sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 \
    || die "required tool not found on PATH: $1"
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"

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
profile_dir="$(dirname "${profile_path}")"

if [ -n "${jobs}" ] && ! [[ "${jobs}" =~ ^[1-9][0-9]*$ ]]; then
  die "--jobs must be a positive integer"
fi
if [ -n "${target}" ] && ! [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  die "invalid recipe attribute name: ${target}"
fi

require_cmd nickel
require_cmd bobr
require_cmd fsobj-hash

# Resolve the profile through its contract, so a typo in a field name or the
# wrong type for one is reported here rather than partway into a build. The
# result comes back as shell assignments: relative paths already made absolute
# against the profile's own directory, defaults already filled, and the overlay
# list already turned into the Nickel expression the request needs.
resolved="$(
  nickel export --format raw <<EOF_PROFILE || die "invalid build profile '${profile_path}'"
let contracts = import "${recipes_path}/build-profile.ncl" in
let profile | contracts.Profile = import "${profile_path}" in
let absolute = fun path =>
  if std.string.is_match "^/" path then path else "${profile_dir}/" ++ path
in
let store = absolute profile.store in
let quote = fun value => "'" ++ value ++ "'" in
let overlays =
  if std.array.length profile.overlays == 0 then
    "[]"
  else
    # Each file may hold one overlay or an array of them; normalize to an array
    # and flatten, so both spellings work.
    "(std.array.flatten (std.array.map (fun o => if std.is_function o then [o] else o) ["
    ++ std.string.join ", " (std.array.map (fun p => "import \"" ++ absolute p ++ "\"") profile.overlays)
    ++ "]))"
in
std.string.join "\n" [
  "profile_target=" ++ quote profile.target,
  "profile_store=" ++ quote store,
  "profile_logs=" ++ quote (if profile.logs == "" then store ++ "/logs" else absolute profile.logs),
  "profile_work=" ++ quote (if profile.work == "" then store ++ "/work" else absolute profile.work),
  "profile_jobs=" ++ quote (std.string.from_number profile.jobs),
  "profile_quiet=" ++ quote (if profile.quiet then "1" else "0"),
  "profile_podman_unshare=" ++ quote (if profile.podman_unshare then "1" else "0"),
  "profile_overlays=" ++ quote overlays,
]
EOF_PROFILE
)"
eval "${resolved}"

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

# The recipes and the bobr on PATH have to agree on the request format. Checking
# here turns a mismatch into one sentence, ahead of the seconds it takes to
# lower the recipes.
recipes_schema="$(nickel export --format raw "${recipes_path}/request-schema.ncl")"
bobr_version="$(bobr --version 2>/dev/null)" || die "'bobr --version' failed; is the binary on PATH usable?"
bobr_schema="$(printf '%s' "${bobr_version}" | sed -n 's/.*(request \(.*\))$/\1/p')"
if [ -z "${bobr_schema}" ]; then
  die "cannot read the request schema from '${bobr_version}'; bobr is too old for these recipes (expected ${recipes_schema})"
fi
if [ "${bobr_schema}" != "${recipes_schema}" ]; then
  die "these recipes emit ${recipes_schema}, but ${bobr_version} accepts ${bobr_schema}; update the older of the two"
fi

# Local sources are pinned by a lock file next to them. A stale lock would build
# the old content silently, so refuse rather than write into the recipes tree --
# the caller edited it and should say so. tools/dev/bobr-build-dev.sh refreshes
# them for recipe work.
"${recipes_path}/bin/bobr-update-fsobj-hashes.sh" --check \
  || die "recipe hash locks are stale; refresh them: ${recipes_path}/bin/bobr-update-fsobj-hashes.sh"

# Claims one run: `mkdir` fails rather than reuses, so a name taken by another
# run (or by a previous one) is skipped instead of shared.
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

if [ "${dry_run}" -eq 1 ]; then
  # A dry run creates nothing: it names the directories a real build would have
  # made and stops after lowering.
  run_id="$(date '+%y%m%d%H%M%S')"
else
  mkdir -p "${logs_root}" "${work_root}"
  run_id="$(allocate_run_id)"
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

# Print the wall time of one build phase ("nickel recipes -> json request" or
# "bobr build") to stderr. When BOBR_BUILD_TIMING_LOG names a file, append the
# same line there too -- that lets callers such as bobr-rebuild-world.sh record the
# split without teeing bobr's live progress UI off stderr.
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
  {
    echo "==> profile ${profile_path} resolves to:"
    printf '%s\n' "${resolved}" | sed 's/^profile_/  /'
    echo "==> target: ${target}"
    echo "==> ${bobr_version}"
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
