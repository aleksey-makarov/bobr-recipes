# Shared by bin/bobr-build.sh and bin/bobr-fetch.sh: everything the two do
# identically -- resolving a build profile, claiming a run, checking that the
# recipes and the binary agree on a request format, and timing the phases.
#
# Not executable on its own; source it after setting `tool` to the calling
# script's name (used in messages) and `recipes_path` to this checkout's root.
#
# The profile block lives here rather than in each script for a reason worth
# stating: it was copied once, and the copy quietly fell behind -- the fetch
# side stopped exporting `quiet`, so a profile asking for silence was obeyed by
# one tool and ignored by the other. One place to add a field is one place to
# forget it.

die() {
  echo "${tool}: $*" >&2
  exit 2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 \
    || die "required tool not found on PATH: $1"
}

# Resolves the profile at $1 through its contract and sets the `profile_*`
# variables from it. Relative paths come back absolute against the profile's own
# directory, defaults are filled in, and the two fields that are Nickel values
# rather than scalars -- the overlay list and the fetch limits -- come back as
# Nickel expressions ready to splice into a request.
#
# Every field is exported whether or not the calling script needs it: a script
# that ignores one costs nothing, while a field missing from this list is a
# setting silently ignored by whoever forgot it.
resolve_profile() {
  local profile_path="$1" profile_dir resolved
  profile_dir="$(dirname "${profile_path}")"

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
# Rebuilt as Nickel source rather than passed by re-importing the profile: one
# reading of the profile, and the value is printable, so --dry-run can show the
# limits a fetch run is about to use.
let per_host =
  std.string.join ", " (
    std.array.map
      (fun host => "\"" ++ host ++ "\" = " ++ std.string.from_number (std.record.get host profile.fetch.per_host))
      (std.record.fields profile.fetch.per_host)
  )
in
let fetch =
  "{ per_host_default = " ++ std.string.from_number profile.fetch.per_host_default
  ++ ", max_connections = " ++ std.string.from_number profile.fetch.max_connections
  ++ ", per_host = { " ++ per_host ++ " } }"
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
  "profile_fetch=" ++ quote fetch,
]
EOF_PROFILE
  )"
  eval "${resolved}"
  # Kept for --dry-run, which shows the caller what its profile came to.
  profile_resolved="${resolved}"
}

# Dies unless the request format these recipes emit is the one the binary
# accepts. $1 is the schema file, $2 the binary; the binary's `--version` line
# is left in `tool_version` for the caller to print.
#
# Checked before anything slow so a mismatched pair costs one sentence rather
# than the seconds it takes to lower the recipes.
check_request_schema() {
  local schema_file="$1" binary="$2" recipes_schema binary_schema
  recipes_schema="$(nickel export --format raw "${schema_file}")"
  tool_version="$("${binary}" --version 2>/dev/null)" \
    || die "'${binary} --version' failed; is the binary on PATH usable?"
  binary_schema="$(printf '%s' "${tool_version}" | sed -n 's/.*(request \(.*\))$/\1/p')"
  if [ -z "${binary_schema}" ]; then
    die "cannot read the request schema from '${tool_version}'; ${binary} is too old for these recipes (expected ${recipes_schema})"
  fi
  if [ "${binary_schema}" != "${recipes_schema}" ]; then
    die "these recipes emit ${recipes_schema}, but ${tool_version} accepts ${binary_schema}; update the older of the two"
  fi
}

# Claims one run under $1 (logs) and $2 (work) and echoes its id: `mkdir` fails
# rather than reuses, so a name taken by another run (or by a previous one) is
# skipped instead of shared.
allocate_run_id() {
  local logs_root="$1" work_root="$2" base attempt candidate
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

# Prints the wall time of one phase to stderr. When BOBR_BUILD_TIMING_LOG names
# a file, appends the same line there too -- that lets callers such as
# bobr-rebuild-world.sh record the split without teeing the live progress UI off
# stderr.
report_phase_time() {
  local label="$1" start="$2" end="$3" line
  line="$(awk -v l="${label}" -v s="${start}" -v e="${end}" \
    'BEGIN { printf "==> %s: %.2fs", l, e - s }')"
  printf '%s\n' "${line}" >&2
  if [ -n "${BOBR_BUILD_TIMING_LOG:-}" ]; then
    printf '%s\n' "${line}" >> "${BOBR_BUILD_TIMING_LOG}"
  fi
}
