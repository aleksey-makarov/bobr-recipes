#!/usr/bin/env bash

# Rebuild the whole world into a fresh, timestamped store.
#
# Creates <workspace>/bobr-store.<YYMMDDhhmmss>, records the bobr/bobr-recipes
# commits, seeds source objects from the previous store (hardlinks, so tarballs
# are not re-fetched), and runs the build. Only after the build succeeds does it
# repoint the bobr-store symlink at the new store. The build itself runs
# strictly through bobr-build.sh.
#
# It does NOT pull git repos or build the bobr binaries: it builds the current
# checkout, and bobr-build.sh hard-checks that the binaries exist.
#
# Usage: bobr-rebuild-world.sh [--jobs N] [--podman-unshare] [pkgs-attr]
#   pkgs-attr defaults to all_test_artifacts.

set -euo pipefail

usage() {
  echo "usage: $0 [--jobs N] [--podman-unshare] [pkgs-attr]" >&2
}

store_basename_is_timetagged() {
  [[ "$1" =~ ^bobr-store\.[0-9]{12}$ ]]
}

# Latest timestamped store other than the current one (lexicographic order works
# for the zero-padded timestamps).
find_previous_store() {
  local current_store="$1" candidate previous=""
  shopt -s nullglob
  for candidate in "${workspace_root}"/bobr-store.*; do
    [ -d "${candidate}" ] || continue
    [ "${candidate}" = "${current_store}" ] && continue
    store_basename_is_timetagged "$(basename "${candidate}")" || continue
    if [ -z "${previous}" ] \
      || [[ "$(basename "${candidate}")" > "$(basename "${previous}")" ]]; then
      previous="${candidate}"
    fi
  done
  shopt -u nullglob
  printf '%s\n' "${previous}"
}

# Hardlink one object (file or directory) into the new store, atomically and
# only if absent. `cp -al` recurses, so directory objects (e.g. OCI layouts)
# are handled too.
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

seed_source_objects() {
  local previous_store="$1" target_store="$2" request_json="$3"
  local object_hash source_object target_object
  local total=0 linked=0 already=0 missing=0

  if [ -z "${previous_store}" ]; then
    log "seed: no previous store found"
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    log "seed: skipped (jq not found)"
    return 0
  fi

  log "seed source objects from ${previous_store}"
  mkdir -p "${target_store}/objects"
  while IFS= read -r object_hash; do
    [ -n "${object_hash}" ] || continue
    total=$((total + 1))
    source_object="${previous_store}/objects/${object_hash}"
    target_object="${target_store}/objects/${object_hash}"
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
    jq -r '.nodes[] | select(.tag == "Source") | .object_hash' "${request_json}" | sort -u
  )
  log "seed: total=${total} linked=${linked} already=${already} missing=${missing}"
}

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

jobs=""
podman_unshare=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --jobs | -j)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      jobs="$2"
      shift 2
      ;;
    --podman-unshare)
      podman_unshare=1
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    --*)
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

[ "$#" -le 1 ] || { usage; exit 2; }
attr="${1:-all_test_artifacts}"
if [ -n "${jobs}" ] && ! [[ "${jobs}" =~ ^[1-9][0-9]*$ ]]; then
  echo "bobr-rebuild-world.sh: --jobs must be a positive integer" >&2
  exit 2
fi

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_repo="$(cd "$(dirname "${script_path}")/.." && pwd)"
workspace_root="$(cd "${recipes_repo}/.." && pwd)"
bobr_repo="${workspace_root}/bobr"
bobr_build="${recipes_repo}/tools/bobr-build.sh"
[ -x "${bobr_build}" ] || { echo "missing bobr-build.sh: ${bobr_build}" >&2; exit 2; }

timetag="$(date '+%y%m%d%H%M%S')"
store_root="${workspace_root}/bobr-store.${timetag}"
store_link="${workspace_root}/bobr-store"
hashes_file="${store_root}/hashes.txt"
request_json="${store_root}/request.json"
script_log="${store_root}/rebuild-world.log"
host_stats_log="${store_root}/host-stats.log"

echo "==> create store ${store_root}" >&2
mkdir "${store_root}"
touch "${script_log}" "${host_stats_log}"

log "store=${store_root}"
log "target=${attr}"
log "cli_jobs=${jobs:-default}"
log_host_snapshot "after-store-create"

git_head() { git -C "$1" rev-parse HEAD 2>/dev/null || echo unknown; }
{
  printf 'bobr %s\n' "$(git_head "${bobr_repo}")"
  printf 'bobr-recipes %s\n' "$(git_head "${recipes_repo}")"
} > "${hashes_file}"

build_args=(--store "${store_root}")
if [ -n "${jobs}" ]; then
  build_args+=(--jobs "${jobs}")
fi
if [ "${podman_unshare}" -eq 1 ]; then
  build_args+=(--podman-unshare)
fi

# Export the request once (through bobr-build.sh) to learn the source objects to
# seed; this also refreshes the fsobj-hash locks, exactly like the real build.
echo "==> export request for ${attr}" >&2
# bobr-build.sh prints the `nickel recipes -> JSON request` time on stderr;
# capture its stderr into the log too. The export step has no live progress UI,
# so teeing stderr is safe here (unlike the build pass below).
"${bobr_build}" --dry-run --store "${store_root}" "${attr}" \
  > "${request_json}" 2> >(tee -a "${script_log}" >&2)

if command -v jq >/dev/null 2>&1; then
  log "request_source_objects=$(
    jq -r '[.nodes[] | select(.tag == "Source") | .object_hash] | unique | length' "${request_json}"
  )"
  log "request_sandbox_nodes=$(
    jq -r '[.nodes[] | select(.tag == "Sandbox")] | length' "${request_json}"
  )"
fi

previous_store="$(find_previous_store "${store_root}")"
log "previous_store=${previous_store:-none}"
log_host_snapshot "before-seed"
seed_started_at="$(date '+%s')"
seed_source_objects "${previous_store}" "${store_root}" "${request_json}"
log "seed_seconds=$(( $(date '+%s') - seed_started_at ))"
log_host_snapshot "after-seed"

echo "==> build ${attr}" >&2
log_host_snapshot "before-build"
# GNU time (if present) writes its report to a temp file via -o, so bobr's live
# progress UI on stderr is untouched; afterwards we print it and log it. Wall
# time via date is the fallback.
build_started_at="$(date '+%s')"
time_bin="$(type -P time || true)"
time_report="$(mktemp)"
build_status=0
if [ -n "${time_bin}" ]; then
  "${time_bin}" -o "${time_report}" \
    -f '==> build time: real %e s, user %U s, sys %S s, maxrss %M KB' \
    "${bobr_build}" "${build_args[@]}" "${attr}" || build_status=$?
else
  "${bobr_build}" "${build_args[@]}" "${attr}" || build_status=$?
fi
if [ -s "${time_report}" ]; then
  tee -a "${script_log}" < "${time_report}" >&2
fi
rm -f "${time_report}"
log "build_seconds=$(( $(date '+%s') - build_started_at ))"
[ "${build_status}" -eq 0 ] || exit "${build_status}"
log_host_snapshot "after-build"

# The build succeeded: repoint the convenience symlink at the new store.
# Overwrite an existing symlink; leave any non-symlink of that name untouched.
if [ -L "${store_link}" ] || [ ! -e "${store_link}" ]; then
  ln -sfnT "$(basename "${store_root}")" "${store_link}"
  echo "==> link: ${store_link} -> $(basename "${store_root}")" >&2
fi

echo "==> store: ${store_root}" >&2
echo "==> hashes: ${hashes_file}" >&2
echo "==> request: ${request_json}" >&2
echo "==> script log: ${script_log}" >&2
echo "==> host stats: ${host_stats_log}" >&2
