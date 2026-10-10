# shellcheck shell=bash
# This sourced library consumes caller context and publishes profile_* names.
# shellcheck disable=SC2034,SC2154

# Shared shell support for `bobr-build.sh`: resolving a build profile, checking
# that the recipes and binary agree on a request format, and timing phases.
#
# Not executable on its own; source it after setting `tool` to the calling
# script's name (used in messages) and `recipes_path` to this checkout's root.
#
# Keeping profile lowering separate from orchestration also makes every profile
# field pass through one auditable boundary.

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
# directory and defaults are filled in. The package set and goals remain Nickel
# values in the profile itself; the build driver imports them directly while
# lowering the request.
#
# Every field is exported whether or not the calling script needs it: a script
# that ignores one costs nothing, while a field missing from this list is a
# setting silently ignored by whoever forgot it. Optional output publication
# is represented by an enable flag, scalar variables, and one Bash array; it is
# deliberately not serialized into the Bobr request.
resolve_profile() {
  local profile_path="$1" profile_dir resolved
  profile_dir="$(dirname "${profile_path}")"

  resolved="$(
    nickel export --format raw <<EOF_PROFILE
let contracts = import "${recipes_path}/profiles/contracts.ncl" in
let profile | contracts.Profile = import "${profile_path}" in
let absolute = fun path =>
  if std.string.is_match "^/" path then path else "${profile_dir}/" ++ path
in
let store = absolute profile.store in
# Shell single quotes are literal except that a quote itself ends them. Emit
# the standard '"'"' sequence for each embedded quote before this generated
# shell fragment is evaluated below.
let quote = fun value =>
  "'" ++ std.string.replace "'" "'\"'\"'" value ++ "'"
in
let assignment = fun name => fun value => name ++ "=" ++ quote value in
let boolean = fun value => if value then "1" else "0" in
let shell_array = fun values =>
  "(" ++ std.string.join " " (std.array.map quote values) ++ ")"
in
# Rebuilt as Nickel source rather than passed by re-importing the profile: one
# reading of the profile, and the value is printable, so --dry-run can show the
# acquisition limits a run is about to use.
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
  ++ ", max_local_jobs = " ++ std.string.from_number profile.fetch.max_local_jobs
  ++ ", per_host = { " ++ per_host ++ " } }"
in
let progress =
  if profile.progress.mode == "fixed" then
    "{ mode = \"fixed\", max_lines = "
    ++ std.string.from_number profile.progress.max_lines ++ " }"
  else
    "{ mode = \"" ++ profile.progress.mode ++ "\" }"
in
let resolve_provider = fun raw_entry =>
  let entry = contracts.validate_secondary_provider raw_entry in
  {
    name = entry.name,
    mappings = entry.mappings,
    content = entry.content,
  }
  & (if std.record.has_field "local" entry then
    {
      local = { store = absolute entry.local.store }
        & (if std.record.has_field "transfer" entry.local then
          { transfer = entry.local.transfer }
        else
          {}),
    }
  else
    {
      remote = {
        master_url = entry.remote.master_url,
        trusted_keys = std.array.map absolute entry.remote.trusted_keys,
        ca_bundle =
          if entry.remote.ca_bundle == "" then "" else absolute entry.remote.ca_bundle,
      },
    })
in
let secondaries_json = std.serialize 'Json {
    repository_cache =
      if profile.secondaries.repository_cache == "" then
        store ++ "/repository-cache"
      else
        absolute profile.secondaries.repository_cache,
    providers = std.array.map resolve_provider profile.secondaries.providers,
  }
in
let secondaries =
  "(std.deserialize 'Json " ++ std.serialize 'Json secondaries_json ++ ")"
in
let has_output_repository =
  std.record.has_field "output_repository" profile
in
let output_repository_lines =
  if !has_output_repository then [
    "profile_output_repository_enabled='0'",
    "profile_output_repository_create_bucket_if_missing=''",
    "profile_output_repository_repository=''",
    "profile_output_repository_endpoint_url=''",
    "profile_output_repository_region=''",
    "profile_output_repository_credentials_file=''",
    "profile_output_repository_credentials_profile=''",
    "profile_output_repository_ca_bundle=''",
    "profile_output_repository_master_url=''",
    "profile_output_repository_data_base_url=''",
    "profile_output_repository_trusted_keys=()",
    "profile_output_repository_cache=''",
    "profile_output_repository_candidate=''",
    "profile_output_repository_max_active_content_bytes=''",
    "profile_output_repository_max_current_slots=''",
    "profile_output_repository_retention=''",
  ] else
    let output = profile.output_repository in
    let trusted_keys =
      if std.array.length output.trusted_keys == 0 then
        ["${recipes_path}/signing-key-1.pub.pem"]
      else
        std.array.map absolute output.trusted_keys
    in [
      assignment "profile_output_repository_enabled" "1",
      assignment
        "profile_output_repository_create_bucket_if_missing"
        (boolean output.create_bucket_if_missing),
      assignment "profile_output_repository_repository" output.repository,
      assignment "profile_output_repository_endpoint_url" output.endpoint_url,
      assignment "profile_output_repository_region" output.region,
      assignment
        "profile_output_repository_credentials_file"
        (if output.credentials_file == "" then "" else absolute output.credentials_file),
      assignment
        "profile_output_repository_credentials_profile"
        output.credentials_profile,
      assignment
        "profile_output_repository_ca_bundle"
        (if output.ca_bundle == "" then "" else absolute output.ca_bundle),
      assignment "profile_output_repository_master_url" output.master_url,
      assignment "profile_output_repository_data_base_url" output.data_base_url,
      "profile_output_repository_trusted_keys=" ++ shell_array trusted_keys,
      assignment
        "profile_output_repository_cache"
        (if output.cache == "" then store ++ "/repository-cache" else absolute output.cache),
      assignment "profile_output_repository_candidate" (absolute output.candidate),
      assignment
        "profile_output_repository_max_active_content_bytes"
        (std.string.from_number output.rotation.max_active_content_bytes),
      assignment
        "profile_output_repository_max_current_slots"
        (std.string.from_number output.rotation.max_current_slots),
      assignment "profile_output_repository_retention" output.rotation.retention,
    ]
in
std.string.join "\n" ([
  "profile_store=" ++ quote store,
  "profile_logs=" ++ quote (if profile.logs == "" then store ++ "/logs" else absolute profile.logs),
  "profile_work=" ++ quote (if profile.work == "" then store ++ "/work" else absolute profile.work),
  "profile_jobs=" ++ quote (std.string.from_number profile.jobs),
  "profile_quiet=" ++ quote (if profile.quiet then "1" else "0"),
  "profile_progress=" ++ quote progress,
  "profile_podman_unshare=" ++ quote (if profile.podman_unshare then "1" else "0"),
  "profile_goals_json=" ++ quote
    ("[" ++ std.string.join "," (
      std.array.map (fun goal => std.serialize 'Json goal.name) profile.goals
    ) ++ "]"),
  "profile_fetch=" ++ quote fetch,
  "profile_secondaries=" ++ quote secondaries,
] @ output_repository_lines)
EOF_PROFILE
  )" || die "invalid build profile '${profile_path}'"
  eval "${resolved}"
  # Kept for --dry-run, which shows the caller what its profile came to.
  profile_resolved="${resolved}"
}

# Dies unless the request format these recipes emit is the one the binary
# accepts. $1 is the schema file, $2 the binary. Compatibility is read from
# machine-readable `--build-info`; the human `--version` line is left in
# `tool_version` for the caller to print.
#
# Checked before anything slow so a mismatched pair costs one sentence rather
# than the seconds it takes to lower the recipes.
check_request_schema() {
  local schema_file="$1" binary="$2" recipes_schema binary_schema
  recipes_schema="$(nickel export --format raw "${schema_file}")"
  tool_version="$("${binary}" --version 2>/dev/null)" \
    || die "'${binary} --version' failed; is the binary on PATH usable?"
  tool_build_info="$("${binary}" --build-info 2>/dev/null)" \
    || die "'${binary} --build-info' failed; ${binary} is too old for these recipes (expected ${recipes_schema})"
  [[ "${tool_build_info}" != *$'\n'* ]] \
    || die "'${binary} --build-info' returned more than one line"
  binary_schema="$(
    printf '%s' "${tool_build_info}" \
      | sed -n 's/^{"version":"[^"]*","request_schema":"\([^"]*\)","provenance":.*}$/\1/p'
  )"
  if [ -z "${binary_schema}" ]; then
    die "cannot read request schema from '${tool_build_info}'; expected compact bobr build information"
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

# Prints the wall time of one phase to stderr.
report_phase_time() {
  local label="$1" start="$2" end="$3" line
  line="$(awk -v l="${label}" -v s="${start}" -v e="${end}" \
    'BEGIN { printf "==> %s: %.2fs", l, e - s }')"
  printf '%s\n' "${line}" >&2
}
