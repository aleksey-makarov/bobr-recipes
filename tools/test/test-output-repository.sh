#!/usr/bin/env bash
# JSON documents are deliberately transported as literal environment values to
# the fake executable below; they are data, not shell fragments.
# shellcheck disable=SC2089,SC2090

set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/../.." && pwd)"
tool="test-output-repository.sh"
# shellcheck source=build-profile/profile-lib.sh
. "${recipes_path}/build-profile/profile-lib.sh"
# shellcheck source=build-profile/output-repository-lib.sh
. "${recipes_path}/build-profile/output-repository-lib.sh"

temporary="$(mktemp -d)"
trap 'rm -rf "${temporary}"' EXIT

fail() {
  echo "test-output-repository.sh: $*" >&2
  exit 1
}

assert_equal() {
  local expected="$1" actual="$2" description="$3"
  [ "${actual}" = "${expected}" ] \
    || fail "${description}: expected '${expected}', got '${actual}'"
}

format_logged_command() {
  local command_name="$1"
  shift

  printf '%s' "${command_name}"
  printf ' <%s>' "$@"
  printf ' env=<%s>|<%s>|<%s>|<%s>' \
    "${profile_output_repository_endpoint_url}" \
    "${profile_output_repository_region}" \
    "${profile_output_repository_credentials_file}" \
    "${profile_output_repository_credentials_profile}"
}

expected_status() {
  local -a args=(
    --repository "${profile_output_repository_repository}"
    --master-url "${profile_output_repository_master_url}"
    --cache "${profile_output_repository_cache}"
  )
  [ "${profile_quiet}" -eq 0 ] || args+=(--quiet)
  local trusted_key
  for trusted_key in "${profile_output_repository_trusted_keys[@]}"; do
    args+=(--trusted-key "${trusted_key}")
  done
  args+=(--ca-bundle "${profile_output_repository_ca_bundle}")
  args+=(--compact --scan-storage)
  format_logged_command status "${args[@]}"
}

expected_init() {
  format_logged_command init \
    --repository "${profile_output_repository_repository}" \
    --ca-bundle "${profile_output_repository_ca_bundle}"
}

expected_prepare() {
  local data_base_url="$1"
  shift
  local -a args=(
    --store "${profile_store}"
    --repository "${profile_output_repository_repository}"
    --master-url "${profile_output_repository_master_url}"
    --cache "${profile_output_repository_cache}"
    --output "${profile_output_repository_candidate}"
  )
  [ "${profile_quiet}" -eq 0 ] || args+=(--quiet)
  local trusted_key
  for trusted_key in "${profile_output_repository_trusted_keys[@]}"; do
    args+=(--trusted-key "${trusted_key}")
  done
  args+=(--ca-bundle "${profile_output_repository_ca_bundle}")
  [ -z "${data_base_url}" ] \
    || args+=(--data-base-url "${data_base_url}")
  args+=("$@")
  format_logged_command prepare "${args[@]}"
}

assert_commands() {
  local expected="" line actual
  for line in "$@"; do
    [ -z "${expected}" ] || expected+=$'\n'
    expected+="${line}"
  done
  actual="$(cat "${MOCK_LOG}")"
  assert_equal "${expected}" "${actual}" "repository command log"
}

context_count() {
  find "${temporary}/store/logs" -mindepth 2 -maxdepth 2 \
    -name context.json -type f 2>/dev/null | wc -l | tr -d '[:space:]'
}

catalog_count() {
  find "${temporary}/store/logs" -mindepth 2 -maxdepth 2 \
    -name recipe-catalog.json -type f 2>/dev/null | wc -l \
    | tr -d '[:space:]'
}

assert_context_outcomes() {
  local expected_success="$1" expected_failed="$2"
  local -a contexts
  mapfile -t contexts < <(
    find "${temporary}/store/logs" -mindepth 2 -maxdepth 2 \
      -name context.json -type f | sort
  )
  jq -s -e \
    --argjson successes "${expected_success}" \
    --argjson failures "${expected_failed}" '
      all(.[];
        .schema == "bobr-run-context-v2"
        and (.run_id | type == "string")
        and .goals == ["glibc-gen1-2.42"]
        and .bobr.version == "test"
        and (.recipes.git_commit | type == "string")
        and (.recipes.git_dirty | type == "boolean")
      )
      and ([.[] | select(.outcome == "success")] | length) == $successes
      and ([.[] | select(.outcome == "failed")] | length) == $failures
      and ([.[] | select(.outcome == "running")] | length) == 0
    ' "${contexts[@]}" >/dev/null \
    || fail "unexpected build run contexts"
}

mkdir -p "${temporary}/bin" "${temporary}/store" "${temporary}/cache"
touch "${temporary}/credentials" "${temporary}/ca.pem" \
  "${temporary}/key-one.pem" "${temporary}/key-two.pem"

cat > "${temporary}/bin/bobr-repo" <<'EOF_MOCK'
#!/usr/bin/env bash
set -euo pipefail

{
  printf '%s' "$1"
  shift
  printf ' <%s>' "$@"
  printf ' env=<%s>|<%s>|<%s>|<%s>\n' \
    "${AWS_ENDPOINT_URL_S3:-}" "${AWS_REGION:-}" \
    "${AWS_SHARED_CREDENTIALS_FILE:-}" "${AWS_PROFILE:-}"
} >> "${MOCK_LOG}"

command_name="$(sed -n '$s/^\([^ ]*\).*/\1/p' "${MOCK_LOG}")"
if [ "${MOCK_FAIL_COMMAND:-}" = "${command_name}" ]; then
  exit 17
fi

case "${command_name}" in
  status)
    count=0
    [ ! -f "${MOCK_STATUS_COUNT}" ] \
      || read -r count < "${MOCK_STATUS_COUNT}"
    count=$((count + 1))
    printf '%s\n' "${count}" > "${MOCK_STATUS_COUNT}"
    sed -n "${count}p" "${MOCK_STATUS_RESPONSES}"
    ;;
  init)
    ;;
  prepare)
    printf '%s\n' "${MOCK_PREPARE_RESULT}"
    ;;
  *)
    echo "unexpected mock command: ${command_name}" >&2
    exit 18
    ;;
esac
EOF_MOCK
chmod +x "${temporary}/bin/bobr-repo"

export PATH="${temporary}/bin:${PATH}"
export MOCK_LOG="${temporary}/commands.log"
export MOCK_STATUS_COUNT="${temporary}/status-count"
export MOCK_STATUS_RESPONSES="${temporary}/status-responses"
unset MOCK_FAIL_COMMAND

reset_profile() {
  : > "${MOCK_LOG}"
  rm -f "${MOCK_STATUS_COUNT}"
  unset MOCK_FAIL_COMMAND
  MOCK_PREPARE_RESULT='{"result":"candidate"}'
  export MOCK_PREPARE_RESULT

  profile_output_repository_enabled=1
  profile_output_repository_create_bucket_if_missing=0
  profile_output_repository_repository="s3://test-repository"
  profile_output_repository_endpoint_url="https://s3.example.test"
  profile_output_repository_region="test-region-1"
  profile_output_repository_credentials_file="${temporary}/credentials"
  profile_output_repository_credentials_profile="publisher"
  profile_output_repository_ca_bundle="${temporary}/ca.pem"
  profile_output_repository_master_url="https://repo.example.test/master"
  profile_output_repository_data_base_url=""
  profile_output_repository_trusted_keys=(
    "${temporary}/key-one.pem"
    "${temporary}/key-two.pem"
  )
  profile_output_repository_cache="${temporary}/cache"
  profile_output_repository_candidate="${temporary}/candidate.cbor"
  profile_output_repository_max_active_content_bytes=200
  profile_output_repository_max_current_slots=3
  profile_output_repository_retention=1d
  profile_store="${temporary}/store"
  profile_quiet=0
}

run_stage() {
  local status=0
  (run_output_repository_stage) > "${temporary}/stdout" \
    2> "${temporary}/stderr" || status="$?"
  return "${status}"
}

run_stage_ok() {
  if ! run_stage; then
    cat "${temporary}/stderr" >&2
    fail "publication stage failed unexpectedly"
  fi
}

write_statuses() {
  printf '%s\n' "$@" > "${MOCK_STATUS_RESPONSES}"
}

# A profile without output_repository returns before looking for publication
# tools or touching repository state.
reset_profile
profile_output_repository_enabled=0
PATH="${temporary}/empty-path" run_stage_ok
assert_equal "" "$(cat "${temporary}/stdout")" "disabled stdout"
assert_equal "" "$(cat "${MOCK_LOG}")" "disabled command log"

# Missing buckets are initialized only when explicitly allowed, re-read, and
# then receive an initial append. Machine-readable output remains internal.
reset_profile
profile_output_repository_create_bucket_if_missing=1
profile_output_repository_data_base_url="https://data.example.test/"
write_statuses \
  '{"state":"missing","current_slots":0,"active_slot":null}' \
  '{"state":"empty","current_slots":0,"active_slot":null}'
run_stage_ok
assert_equal "" "$(cat "${temporary}/stdout")" "initial publication stdout"
assert_commands \
  "$(expected_status)" \
  "$(expected_init)" \
  "$(expected_status)" \
  "$(expected_prepare 'https://data.example.test/' \
    --append --retention 1d)"

# Existing active slots below the threshold append without requiring an
# explicit data URL; bobr-repo gets it from the signed master.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":2,"active_slot":{"serial":7,"content_bytes":199}}'
run_stage_ok
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"

# Equality starts a new slot when room remains.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":2,"active_slot":{"serial":7,"content_bytes":200}}'
run_stage_ok
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --add-slot)"

# Once the configured number of current slots exists, a full active slot is
# rotated and the grace period is passed through.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":3,"active_slot":{"serial":7,"content_bytes":201}}'
run_stage_ok
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --rotate --retention 1d)"

# `unchanged` is a successful result and is reported only on stderr.
reset_profile
MOCK_PREPARE_RESULT='{"result":"unchanged"}'
export MOCK_PREPARE_RESULT
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
run_stage_ok
assert_equal "" "$(cat "${temporary}/stdout")" "unchanged stdout"
grep -F 'output repository is unchanged' "${temporary}/stderr" >/dev/null \
  || fail "unchanged result was not reported"
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"

# Quiet publication forwards the setting to long-running repository commands,
# while wrapper phase timings remain visible.
reset_profile
profile_quiet=1
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
run_stage_ok
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"
grep -F '==> bobr-repo status:' "${temporary}/stderr" >/dev/null \
  || fail "status timing was not reported"
grep -F '==> bobr-repo prepare:' "${temporary}/stderr" >/dev/null \
  || fail "prepare timing was not reported"

# Operational failures are fatal and stop before the next repository
# operation. Check status, init, and prepare independently.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
MOCK_FAIL_COMMAND=status
export MOCK_FAIL_COMMAND
if run_stage; then
  fail "failed status command was accepted"
fi
assert_commands "$(expected_status)"
grep -F '==> bobr-repo status:' "${temporary}/stderr" >/dev/null \
  || fail "failed status timing was not reported"

reset_profile
profile_output_repository_create_bucket_if_missing=1
write_statuses \
  '{"state":"missing","current_slots":0,"active_slot":null}'
MOCK_FAIL_COMMAND=init
export MOCK_FAIL_COMMAND
if run_stage; then
  fail "failed init command was accepted"
fi
assert_commands "$(expected_status)" "$(expected_init)"

reset_profile
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
MOCK_FAIL_COMMAND=prepare
export MOCK_FAIL_COMMAND
if run_stage; then
  fail "failed prepare command was accepted"
fi
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"

# A missing bucket without permission to create it is a hard publication
# failure and never reaches prepare.
reset_profile
write_statuses \
  '{"state":"missing","current_slots":0,"active_slot":null}'
if (run_stage); then
  fail "missing bucket without initialization permission was accepted"
fi
assert_commands "$(expected_status)"

# Empty and malformed repositories fail before prepare. In particular, the
# initial master cannot be constructed without a content base URL.
reset_profile
write_statuses \
  '{"state":"empty","current_slots":0,"active_slot":null}'
if (run_stage); then
  fail "empty repository without data_base_url was accepted"
fi
assert_commands "$(expected_status)"

reset_profile
write_statuses '{"state":"ready","current_slots":1,"active_slot":null}'
if (run_stage); then
  fail "invalid status JSON was accepted"
fi
assert_commands "$(expected_status)"

reset_profile
MOCK_PREPARE_RESULT='{"result":"surprise"}'
export MOCK_PREPARE_RESULT
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
if (run_stage); then
  fail "invalid prepare JSON was accepted"
fi
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"

# Exercise the actual build wrapper as well as the sourced module. Bobr's goal
# hash must reach stdout immediately; a failed build must skip publication, and
# a later publication failure must not retract or buffer that hash.
cat > "${temporary}/bin/bobr" <<EOF_BOBR
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "--version" ]; then
  printf '%s\n' 'bobr test (request $(nickel export --format raw "${recipes_path}/request-schema.ncl")) (provenance unknown)'
  exit 0
fi
if [ "\${1:-}" = "--build-info" ]; then
  printf '%s\n' '{"version":"test","request_schema":"$(nickel export --format raw "${recipes_path}/request-schema.ncl")","provenance":null}'
  exit 0
fi
cat >/dev/null
printf '%s\n' goal-hash
exit "\${MOCK_BOBR_STATUS:-0}"
EOF_BOBR
chmod +x "${temporary}/bin/bobr"

# A build-only profile must not even inspect publication tools. Put deliberately
# unusable bobr-repo and jq executables first on PATH and exercise the complete
# wrapper, rather than calling the sourced publication module directly.
mkdir -p "${temporary}/broken-bin"
export BROKEN_TOOL_LOG="${temporary}/broken-tools.log"
for broken_tool in bobr-repo jq; do
  cat > "${temporary}/broken-bin/${broken_tool}" <<'EOF_BROKEN'
#!/usr/bin/env bash
printf '%s\n' "${0##*/}" >> "${BROKEN_TOOL_LOG}"
exit 97
EOF_BROKEN
  chmod +x "${temporary}/broken-bin/${broken_tool}"
done

build_only_profile="${temporary}/build-only.ncl"
cat > "${build_only_profile}" <<EOF_PROFILE
let bobrpkgs = import "${recipes_path}/bobrpkgs.ncl" in
let pkgs = bobrpkgs [] in
{
  include pkgs,
  goals = [pkgs.glibc_gen1],
  store = "${temporary}/store",
}
EOF_PROFILE

: > "${BROKEN_TOOL_LOG}"
MOCK_BOBR_STATUS=0 PATH="${temporary}/broken-bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" "${build_only_profile}" \
  > "${temporary}/wrapper-stdout" 2> "${temporary}/wrapper-stderr"
assert_equal "goal-hash" "$(cat "${temporary}/wrapper-stdout")" \
  "build-only wrapper stdout"
assert_equal "" "$(cat "${BROKEN_TOOL_LOG}")" \
  "publication tools used by build-only wrapper"
assert_equal "1" "$(context_count)" "build-only context count"
assert_equal "1" "$(catalog_count)" "build-only catalog count"
assert_context_outcomes 1 0
catalog="$(find "${temporary}/store/logs" -mindepth 2 -maxdepth 2 \
  -name recipe-catalog.json -type f -print -quit)"
jq -e '
  .schema == "bobr-recipe-catalog-v1"
  and (.nodes | length) > 0
  and all(.nodes[];
    (.name | type == "string")
    and (.tag | type == "string")
    and (keys | sort) == ["name", "tag"]
  )
' "${catalog}" >/dev/null || fail "unsafe or invalid recipe catalog"

integration_profile="${temporary}/integration.ncl"
cat > "${integration_profile}" <<EOF_PROFILE
let bobrpkgs = import "${recipes_path}/bobrpkgs.ncl" in
let pkgs = bobrpkgs [] in
{
  include pkgs,
  goals = [pkgs.glibc_gen1],
  store = "${temporary}/store",
  output_repository = {
    repository = "s3://test-repository",
    endpoint_url = "https://s3.example.test",
    region = "test-region-1",
    credentials_file = "credentials",
    credentials_profile = "publisher",
    ca_bundle = "ca.pem",
    master_url = "https://repo.example.test/master",
    trusted_keys = ["key-one.pem", "key-two.pem"],
    cache = "cache",
    candidate = "candidate.cbor",
    rotation = {
      max_active_content_bytes = 200,
      max_current_slots = 3,
      retention = "1d",
    },
  },
}
EOF_PROFILE

# Dry-run lowers a publication profile but creates and publishes nothing. Its
# success must not depend on working repository tools either.
: > "${BROKEN_TOOL_LOG}"
: > "${MOCK_LOG}"
PATH="${temporary}/broken-bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run "${integration_profile}" \
  > "${temporary}/wrapper-stdout" 2> "${temporary}/wrapper-stderr"
assert_equal "" "$(cat "${BROKEN_TOOL_LOG}")" \
  "publication tools used by dry-run wrapper"
assert_equal "" "$(cat "${MOCK_LOG}")" \
  "repository operations used by dry-run wrapper"
assert_equal "1" "$(context_count)" "dry-run context count"
assert_equal "1" "$(catalog_count)" "dry-run catalog count"

reset_profile
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
MOCK_BOBR_STATUS=0 "${recipes_path}/bin/bobr-build.sh" \
  "${integration_profile}" > "${temporary}/wrapper-stdout" \
  2> "${temporary}/wrapper-stderr"
assert_equal "goal-hash" "$(cat "${temporary}/wrapper-stdout")" \
  "wrapper success stdout"
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"
assert_equal "2" "$(context_count)" "successful context count"
assert_equal "2" "$(catalog_count)" "successful catalog count"
assert_context_outcomes 2 0

reset_profile
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
if MOCK_BOBR_STATUS=23 "${recipes_path}/bin/bobr-build.sh" \
  "${integration_profile}" > "${temporary}/wrapper-stdout" \
  2> "${temporary}/wrapper-stderr"; then
  fail "failed build was accepted"
fi
assert_equal "goal-hash" "$(cat "${temporary}/wrapper-stdout")" \
  "failed build stdout"
assert_equal "" "$(cat "${MOCK_LOG}")" \
  "publication after failed build"
assert_equal "3" "$(context_count)" "failed context count"
assert_equal "3" "$(catalog_count)" "failed catalog count"
assert_context_outcomes 2 1

reset_profile
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
MOCK_FAIL_COMMAND=prepare
export MOCK_FAIL_COMMAND
if MOCK_BOBR_STATUS=0 "${recipes_path}/bin/bobr-build.sh" \
  "${integration_profile}" > "${temporary}/wrapper-stdout" \
  2> "${temporary}/wrapper-stderr"; then
  fail "publication failure was accepted"
fi
assert_equal "goal-hash" "$(cat "${temporary}/wrapper-stdout")" \
  "publication failure stdout"
assert_commands \
  "$(expected_status)" \
  "$(expected_prepare '' --append --retention 1d)"
assert_equal "4" "$(context_count)" "publication-failure context count"
assert_equal "4" "$(catalog_count)" "publication-failure catalog count"
assert_context_outcomes 3 1

echo "test-output-repository.sh: all tests passed"
