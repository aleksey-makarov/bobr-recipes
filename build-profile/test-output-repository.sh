#!/usr/bin/env bash
# JSON documents are deliberately transported as literal environment values to
# the fake executable below; they are data, not shell fragments.
# shellcheck disable=SC2089,SC2090

set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"
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

assert_log_contains() {
  local text="$1"
  grep -F -- "${text}" "${MOCK_LOG}" >/dev/null \
    || fail "command log does not contain: ${text}"
}

assert_log_excludes() {
  local text="$1"
  if grep -F -- "${text}" "${MOCK_LOG}" >/dev/null; then
    fail "command log unexpectedly contains: ${text}"
  fi
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
assert_log_contains 'status <--repository> <s3://test-repository>'
assert_log_contains '<--scan-storage>'
assert_log_contains 'init <--repository> <s3://test-repository>'
assert_log_contains 'prepare <--store>'
assert_log_contains '<--append> <--retention> <1d>'
assert_log_contains '<--data-base-url> <https://data.example.test/>'
assert_log_contains \
  'env=<https://s3.example.test>|<test-region-1>|'
assert_log_contains "<${temporary}/credentials>|<publisher>"
assert_log_contains '<--trusted-key>'
assert_log_contains '<--ca-bundle>'

# Existing active slots below the threshold append without requiring an
# explicit data URL; bobr-repo gets it from the signed master.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":2,"active_slot":{"serial":7,"content_bytes":199}}'
run_stage_ok
assert_log_contains '<--append> <--retention> <1d>'
assert_log_excludes '<--data-base-url>'

# Equality starts a new slot when room remains.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":2,"active_slot":{"serial":7,"content_bytes":200}}'
run_stage_ok
assert_log_contains '<--add-slot>'
assert_log_excludes '<--retention>'

# Once the configured number of current slots exists, a full active slot is
# rotated and the grace period is passed through.
reset_profile
write_statuses \
  '{"state":"ready","current_slots":3,"active_slot":{"serial":7,"content_bytes":201}}'
run_stage_ok
assert_log_contains '<--rotate> <--retention> <1d>'

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

# A missing bucket without permission to create it is a hard publication
# failure and never reaches prepare.
reset_profile
write_statuses \
  '{"state":"missing","current_slots":0,"active_slot":null}'
if (run_stage); then
  fail "missing bucket without initialization permission was accepted"
fi
assert_log_excludes 'prepare '

# Empty and malformed repositories fail before prepare. In particular, the
# initial master cannot be constructed without a content base URL.
reset_profile
write_statuses \
  '{"state":"empty","current_slots":0,"active_slot":null}'
if (run_stage); then
  fail "empty repository without data_base_url was accepted"
fi
assert_log_excludes 'prepare '

reset_profile
write_statuses '{"state":"ready","current_slots":1,"active_slot":null}'
if (run_stage); then
  fail "invalid status JSON was accepted"
fi
assert_log_excludes 'prepare '

reset_profile
MOCK_PREPARE_RESULT='{"result":"surprise"}'
export MOCK_PREPARE_RESULT
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
if (run_stage); then
  fail "invalid prepare JSON was accepted"
fi

# Exercise the actual build wrapper as well as the sourced module. Bobr's goal
# hash must reach stdout immediately; a failed build must skip publication, and
# a later publication failure must not retract or buffer that hash.
cat > "${temporary}/bin/bobr" <<EOF_BOBR
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "--version" ]; then
  printf '%s\n' 'bobr test (request $(nickel export --format raw "${recipes_path}/request-schema.ncl"))'
  exit 0
fi
cat >/dev/null
printf '%s\n' goal-hash
exit "\${MOCK_BOBR_STATUS:-0}"
EOF_BOBR
chmod +x "${temporary}/bin/bobr"

integration_profile="${temporary}/integration.ncl"
cat > "${integration_profile}" <<EOF_PROFILE
{
  target = "glibc_gen1",
  store = "${temporary}/store",
  output_repository = {
    repository = "s3://test-repository",
    master_url = "https://repo.example.test/master",
    trusted_keys = ["key-one.pem"],
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

reset_profile
write_statuses \
  '{"state":"ready","current_slots":1,"active_slot":{"serial":1,"content_bytes":1}}'
MOCK_BOBR_STATUS=0 "${recipes_path}/bin/bobr-build.sh" \
  "${integration_profile}" > "${temporary}/wrapper-stdout" \
  2> "${temporary}/wrapper-stderr"
assert_equal "goal-hash" "$(cat "${temporary}/wrapper-stdout")" \
  "wrapper success stdout"
assert_log_contains 'prepare <--store>'

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
assert_log_contains 'prepare <--store>'

echo "test-output-repository.sh: all tests passed"
