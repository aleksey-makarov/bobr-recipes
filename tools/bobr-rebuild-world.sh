#!/usr/bin/env bash

# Rebuilds everything from scratch into a fresh store.
#
# Usage: bobr-rebuild-world.sh [--tests]
#
#   --tests    Realize `test_all` instead of the profile's `world` target.
#
# Install the host tools first with tools/bobr-install.sh. The recipes are
# pulled first, then the target is realized by one real bin/bobr-build.sh
# invocation into <workspace>/bobr-store.<YYMMDDhhmmss>.
# The last successful store is an untrusted hardlink repository: Source content
# is reused lazily, while its build and reuse mappings remain unavailable.
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

run_tests=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --tests)
      run_tests=1
      shift
      ;;
    -h | --help) sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2; exit 0 ;;
    *) die "unexpected argument: $1" ;;
  esac
done

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_repo="$(cd "$(dirname "${script_path}")/.." && pwd)"
workspace_root="$(cd "${recipes_repo}/.." && pwd)"
bobr_root="${workspace_root}/bobr-bin"
bin_dir="${bobr_root}/bin"
commit_file="${bobr_root}/commit.txt"

[ -d "${recipes_repo}/.git" ] || die "missing git repository: ${recipes_repo}"

require_cmd git

echo "==> pull bobr-recipes" >&2
git -C "${recipes_repo}" pull --ff-only

# Whatever a run of bobr needs on PATH. Installation is intentionally separate
# from rebuilding the world, so fail early and point at the exact remedy.
required_binaries=(bobr fsobj-hash bobr-sandbox-launcher)
for binary in "${required_binaries[@]}"; do
  [ -x "${bin_dir}/${binary}" ] \
    || die "missing ${bin_dir}/${binary}; run tools/bobr-install.sh first"
done
[ -f "${commit_file}" ] \
  || die "missing ${commit_file}; run tools/bobr-install.sh first"
bobr_revision="$(tr -d '[:space:]' < "${commit_file}")"
[[ "${bobr_revision}" =~ ^[0-9a-f]{40}$ \
  || "${bobr_revision}" =~ ^[0-9a-f]{64}$ ]] \
  || die "invalid bobr commit in ${commit_file}"

# Make sure this installed set is used even if the caller has not put it on
# PATH.
export PATH="${bin_dir}:${PATH}"

# ---------------------------------------------------------------------------
# the store
# ---------------------------------------------------------------------------

timetag="$(date '+%y%m%d%H%M%S')"
store_root="${workspace_root}/bobr-store.${timetag}"
store_link="${workspace_root}/bobr-store"
hashes_file="${store_root}/hashes.txt"
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

# The convenience link names the last successful rebuild. Resolve it now: the
# link is repointed after success, but this profile must keep naming the old
# store rather than eventually referring to itself.
previous_store=""
if [ -e "${store_link}" ] || [ -L "${store_link}" ]; then
  previous_store="$(readlink -f "${store_link}")" \
    || die "cannot resolve previous store ${store_link}"
  [ -d "${previous_store}" ] \
    || die "previous store is not a directory: ${previous_store}"
fi

# Import the shipped user preset rather than copying it. The generated profile
# records only this rebuild's store and optional previous-world secondary, so
# future preset changes are picked up without rewriting old template text.
{
  printf '(import "%s/build-profile/bobr-user.ncl") & {\n' "${recipes_repo}"
  printf '  store = "%s",\n' "${store_root}"
  if [ -n "${previous_store}" ]; then
    printf '%s\n' \
      '  secondaries = {' \
      '    local_repositories = [{' \
      '      name = "previous-world",'
    printf '      store = "%s",\n' "${previous_store}"
    printf '%s\n' \
      '      trusted = false,' \
      '      transfer = "hardlink",' \
      '    }],' \
      '  },'
  fi
  printf '}\n'
} > "${profile_path}"

git_head() { git -C "$1" rev-parse HEAD 2>/dev/null || echo unknown; }
{
  printf 'bobr %s\n' "${bobr_revision:-unknown}"
  printf 'bobr-recipes %s\n' "$(git_head "${recipes_repo}")"
} > "${hashes_file}"

log "store=${store_root}"
log "bobr=${bobr_revision:-unknown}"
log "previous_store=${previous_store:-none}"
if [ "${run_tests}" -eq 1 ]; then
  log "target=test_all"
else
  log "target=world"
fi
log_host_snapshot "after-store-create"

# bobr-build.sh prints its lowering and realization timings to stderr; pointing
# it at the run log records them there too.
export BOBR_BUILD_TIMING_LOG="${script_log}"

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

build_args=("${profile_path}")
realize_target="world"
if [ "${run_tests}" -eq 1 ]; then
  build_args=(--target test_all "${profile_path}")
  realize_target="test_all"
fi

echo "==> realize ${realize_target}" >&2
log_host_snapshot "before-realize"
realize_started_at="$(date '+%s')"
realize_status=0
run_phase realize \
  "${recipes_repo}/bin/bobr-build.sh" "${build_args[@]}" || realize_status=$?
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
echo "==> script log: ${script_log}" >&2
echo "==> host stats: ${host_stats_log}" >&2
