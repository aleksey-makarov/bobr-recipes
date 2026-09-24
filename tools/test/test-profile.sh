#!/usr/bin/env bash

set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/../.." && pwd)"
tool="test-profile.sh"
# shellcheck source=build-profile/profile-lib.sh
. "${recipes_path}/build-profile/profile-lib.sh"

temporary="$(mktemp -d)"
trap 'rm -rf "${temporary}"' EXIT

fail() {
  echo "test-profile.sh: $*" >&2
  exit 1
}

assert_equal() {
  local expected="$1" actual="$2" description="$3"
  [ "${actual}" = "${expected}" ] \
    || fail "${description}: expected '${expected}', got '${actual}'"
}

write_profile() {
  local path="$1" expression="$2"
  printf '%s\n' "${expression}" > "${path}"
}

reject_profile() {
  local name="$1" expression="$2" path
  path="${temporary}/${name}.ncl"
  write_profile "${path}" "${expression}"
  if (resolve_profile "${path}") >/dev/null 2>&1; then
    fail "invalid profile '${name}' was accepted"
  fi
}

user_profile="${temporary}/user.ncl"
write_profile "${user_profile}" \
  "import \"${recipes_path}/build-profile/bobr-user.ncl\""
resolve_profile "${user_profile}"
assert_equal "world" "${profile_target}" "user target"
assert_equal "${temporary}/bobr-store" "${profile_store}" "user store"
assert_equal "0" "${profile_output_repository_enabled}" "publication disabled"
assert_equal "0" "${#profile_output_repository_trusted_keys[@]}" \
  "disabled trusted-key count"

potato_profile="${temporary}/potato.ncl"
write_profile "${potato_profile}" \
  "(import \"${recipes_path}/build-profile/bobr-potato.ncl\") & { store = \"potato-store\" }"
resolve_profile "${potato_profile}"
assert_equal "${temporary}/potato-store" "${profile_store}" "potato store"
assert_equal "1" "${profile_output_repository_enabled}" "publication enabled"
assert_equal "1" "${profile_output_repository_create_bucket_if_missing}" \
  "potato bucket creation"
assert_equal "s3://bobr" "${profile_output_repository_repository}" \
  "potato repository"
assert_equal "https://192.168.0.169:7070" \
  "${profile_output_repository_endpoint_url}" "potato endpoint"
assert_equal "${temporary}/.config/bobr/aws-credentials" \
  "${profile_output_repository_credentials_file}" "potato credentials"
assert_equal "${temporary}/.config/bobr/local-repository-ca.cert.pem" \
  "${profile_output_repository_ca_bundle}" "potato CA"
assert_equal "https://192.168.0.169:7070/bobr/master" \
  "${profile_output_repository_master_url}" "potato master URL"
assert_equal "https://192.168.0.169:7070/bobr/" \
  "${profile_output_repository_data_base_url}" "potato data URL"
assert_equal "${temporary}/potato-store/repository-cache" \
  "${profile_output_repository_cache}" "default repository cache"
assert_equal "${temporary}/candidate-master.cbor" \
  "${profile_output_repository_candidate}" "default candidate"
assert_equal "${recipes_path}/signing-key-1.pub.pem" \
  "${profile_output_repository_trusted_keys[0]}" "default trusted key"
assert_equal "200000000000" \
  "${profile_output_repository_max_active_content_bytes}" \
  "default active-slot threshold"
assert_equal "3" "${profile_output_repository_max_current_slots}" \
  "default current-slot limit"
assert_equal "1d" "${profile_output_repository_retention}" \
  "default retention"

custom_profile="${temporary}/custom.ncl"
write_profile "${custom_profile}" '
{
  store = "custom-store",
  output_repository = {
    master_url = "https://master.example/repository/master",
    credentials_file = "/secrets/credentials",
    ca_bundle = "tls/ca.pem",
    trusted_keys = ["keys/one.pem", "/keys/two.pem"],
    cache = "cache",
    candidate = "output/candidate.cbor",
    rotation = {
      max_active_content_bytes = 17,
      max_current_slots = 1,
      retention = "0",
    },
  },
}'
resolve_profile "${custom_profile}"
assert_equal "" "${profile_output_repository_data_base_url}" \
  "existing-master data URL"
assert_equal "/secrets/credentials" \
  "${profile_output_repository_credentials_file}" "absolute credentials"
assert_equal "${temporary}/tls/ca.pem" \
  "${profile_output_repository_ca_bundle}" "relative CA"
assert_equal "${temporary}/keys/one.pem" \
  "${profile_output_repository_trusted_keys[0]}" "relative trusted key"
assert_equal "/keys/two.pem" \
  "${profile_output_repository_trusted_keys[1]}" "absolute trusted key"
assert_equal "${temporary}/cache" "${profile_output_repository_cache}" \
  "explicit cache"
assert_equal "${temporary}/output/candidate.cbor" \
  "${profile_output_repository_candidate}" "explicit candidate"
assert_equal "17" "${profile_output_repository_max_active_content_bytes}" \
  "explicit active-slot threshold"
assert_equal "1" "${profile_output_repository_max_current_slots}" \
  "explicit current-slot limit"
assert_equal "0" "${profile_output_repository_retention}" \
  "zero retention"

quoted_profile="${temporary}/quoted.ncl"
write_profile "${quoted_profile}" \
  "{ target = \"world\", store = \"bob's-store\" }"
resolve_profile "${quoted_profile}"
assert_equal "${temporary}/bob's-store" "${profile_store}" \
  "shell-quoted apostrophe"

reject_profile missing-master-url \
  '{ output_repository = {} }'
reject_profile zero-content-threshold \
  '{ output_repository = { master_url = "https://example/master", rotation.max_active_content_bytes = 0 } }'
reject_profile fractional-content-threshold \
  '{ output_repository = { master_url = "https://example/master", rotation.max_active_content_bytes = 1.5 } }'
reject_profile zero-current-slots \
  '{ output_repository = { master_url = "https://example/master", rotation.max_current_slots = 0 } }'
reject_profile fractional-current-slots \
  '{ output_repository = { master_url = "https://example/master", rotation.max_current_slots = 2.5 } }'
reject_profile invalid-retention \
  '{ output_repository = { master_url = "https://example/master", rotation.retention = "1day" } }'
reject_profile empty-retention \
  '{ output_repository = { master_url = "https://example/master", rotation.retention = "" } }'
reject_profile unknown-output-field \
  '{ output_repository = { master_url = "https://example/master", endpoint = "typo" } }'
reject_profile unknown-profile-field \
  '{ output_repositroy = {} }'

# Exercise the real build wrapper through request lowering. A fake bobr is
# sufficient for its schema handshake because --dry-run never invokes a build.
mkdir -p "${temporary}/bin" "${temporary}/request-store"
request_schema="$(nickel export --format raw "${recipes_path}/request-schema.ncl")"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [ "${1:-}" = "--version" ]; then' \
  "  printf '%s\\n' 'bobr test (request ${request_schema}) (provenance unknown)'" \
  '  exit 0' \
  'fi' \
  'if [ "${1:-}" = "--build-info" ]; then' \
  "  printf '%s\\n' '{\"version\":\"test\",\"request_schema\":\"${request_schema}\",\"provenance\":null}'" \
  '  exit 0' \
  'fi' \
  'exit 1' > "${temporary}/bin/bobr"
chmod +x "${temporary}/bin/bobr"
write_profile "${temporary}/request.ncl" \
  "(import \"${recipes_path}/build-profile/bobr-potato.ncl\") & { store = \"request-store\" }"
PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run --target glibc_gen1 \
  "${temporary}/request.ncl" > "${temporary}/request.json" 2> "${temporary}/dry-run.log"
if grep -q 'output_repository' "${temporary}/request.json"; then
  fail "output_repository leaked into the Bobr request"
fi

echo "test-profile.sh: all tests passed"
