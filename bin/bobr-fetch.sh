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
#   --dry-run                print the resolved profile and the JSON request,
#                            fetch nothing
#   -h | --help              show this help
#
# The profile says where the store is and what to fetch; this run's name and
# its log and work directories are minted here, per invocation. `bobr-fetch`
# comes from PATH -- install a release, or build it with
# `cargo build -p bobr-source --bins` in the engine checkout.

set -euo pipefail

die() {
  echo "bobr-fetch.sh: $*" >&2
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
dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      target="$2"
      shift 2
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

if [ -n "${target}" ] && ! [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  die "invalid recipe attribute name: ${target}"
fi

require_cmd nickel
require_cmd bobr-fetch

# Resolve the profile through its contract, exactly as bin/bobr-build.sh does:
# a typo is reported here, not partway into a download run. Only the fields the
# fetcher cares about are exported; the connection limits travel separately,
# straight from the contract-checked profile into the request expression.
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

[ -n "${target}" ] \
  || die "no recipe to fetch for: set 'target' in ${profile_path} or pass --target NAME"
[ -d "${store_path}" ] \
  || die "store does not exist: ${store_path} (create it: mkdir -p '${store_path}')"

# The recipes and the bobr-fetch on PATH have to agree on the request format --
# the same handshake bin/bobr-build.sh does with bobr.
recipes_schema="$(nickel export --format raw "${recipes_path}/fetch-request-schema.ncl")"
fetch_version="$(bobr-fetch --version 2>/dev/null)" \
  || die "'bobr-fetch --version' failed; is the binary on PATH usable?"
fetch_schema="$(printf '%s' "${fetch_version}" | sed -n 's/.*(request \(.*\))$/\1/p')"
if [ -z "${fetch_schema}" ]; then
  die "cannot read the request schema from '${fetch_version}'; bobr-fetch is too old for these recipes (expected ${recipes_schema})"
fi
if [ "${fetch_schema}" != "${recipes_schema}" ]; then
  die "these recipes emit ${recipes_schema}, but ${fetch_version} accepts ${fetch_schema}; update the older of the two"
fi

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
  # A dry run creates nothing: it names the directories a real run would have
  # made and stops after lowering.
  run_id="$(date '+%y%m%d%H%M%S')"
else
  mkdir -p "${logs_root}" "${work_root}"
  run_id="$(allocate_run_id)"
fi
logs_path="${logs_root}/${run_id}"
work_path="${work_root}/${run_id}"

request_expr="(import \"${recipes_path}/request-fetch.ncl\") {
  store_path = \"${store_path}\",
  logs_path = \"${logs_path}\",
  work_path = \"${work_path}\",
  run_id = \"${run_id}\",
  recipes_path = \"${recipes_path}\",
  target_name = \"${target}\",
  overlays = ${overlays_expr},
  fetch = (let profile | (import \"${recipes_path}/build-profile.ncl\").Profile = import \"${profile_path}\" in profile.fetch),
}"

if [ "${dry_run}" -eq 1 ]; then
  {
    echo "==> profile ${profile_path} resolves to:"
    printf '%s\n' "${resolved}" | sed 's/^profile_/  /'
    echo "==> target: ${target}"
    echo "==> ${fetch_version}"
  } >&2
  printf '%s\n' "${request_expr}" | nickel export --format json
  exit 0
fi

request_json="$(mktemp)"
trap 'rm -f "${request_json}"' EXIT
printf '%s\n' "${request_expr}" | nickel export --format json > "${request_json}"

bobr-fetch "${request_json}"
