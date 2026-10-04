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

profile_prelude="let bobrpkgs = import \"${recipes_path}/bobrpkgs.ncl\" in let pkgs = bobrpkgs [] in"
user_profile_value="${profile_prelude} (import \"${recipes_path}/build-profile/bobr-user.ncl\") & { include pkgs, goals = [pkgs.world] }"

user_profile="${temporary}/user.ncl"
write_profile "${user_profile}" "${user_profile_value}"
resolve_profile "${user_profile}"
assert_equal '["world"]' "${profile_goals_json}" "user goals"
assert_equal "${temporary}/bobr-store" "${profile_store}" "user store"
assert_equal "0" "${profile_output_repository_enabled}" "publication disabled"
assert_equal "0" "${#profile_output_repository_trusted_keys[@]}" \
  "disabled trusted-key count"
[[ "${profile_secondaries}" == *"${temporary}/bobr-store/repository-cache"* ]] \
  || fail "default secondary repository cache was not resolved under the store"

potato_profile="${temporary}/potato.ncl"
write_profile "${potato_profile}" \
  "${user_profile_value} & (import \"${recipes_path}/build-profile/output-repo-potato.ncl\") & { store = \"potato-store\" }"
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

layered_profile="${temporary}/layered.ncl"
write_profile "${layered_profile}" \
  "${user_profile_value} & (import \"${recipes_path}/build-profile/output-repo-potato.ncl\") & { fetch.per_host_default = 3, output_repository.create_bucket_if_missing = false }"
resolve_profile "${layered_profile}"
[[ "${profile_fetch}" == *'per_host_default = 3'* ]] \
  || fail "user fetch default override was not preserved"
[[ "${profile_fetch}" == *'"gitlab.freedesktop.org" = 2'* ]] \
  || fail "user profile GitLab limit was not preserved"
assert_equal "0" "${profile_output_repository_create_bucket_if_missing}" \
  "user bucket-creation override"
assert_equal "https://192.168.0.169:7070/bobr/master" \
  "${profile_output_repository_master_url}" \
  "repository fields preserved after leaf override"

custom_profile="${temporary}/custom.ncl"
write_profile "${custom_profile}" "${profile_prelude}"'
{
  include pkgs,
  goals = [pkgs.world],
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
  "${user_profile_value} & { store = \"bob's-store\" }"
resolve_profile "${quoted_profile}"
assert_equal "${temporary}/bob's-store" "${profile_store}" \
  "shell-quoted apostrophe"

reject_profile missing-master-url \
  "${user_profile_value} & { output_repository = {} }"
reject_profile zero-content-threshold \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", rotation.max_active_content_bytes = 0 } }"
reject_profile fractional-content-threshold \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", rotation.max_active_content_bytes = 1.5 } }"
reject_profile zero-current-slots \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", rotation.max_current_slots = 0 } }"
reject_profile fractional-current-slots \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", rotation.max_current_slots = 2.5 } }"
reject_profile invalid-retention \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", rotation.retention = \"1day\" } }"
reject_profile empty-retention \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", rotation.retention = \"\" } }"
reject_profile unknown-output-field \
  "${user_profile_value} & { output_repository = { master_url = \"https://example/master\", endpoint = \"typo\" } }"
reject_profile unknown-profile-field \
  "${user_profile_value} & { output_repositroy = {} }"
reject_profile provider-without-backend \
  "${user_profile_value} & { secondaries.providers = [{ name = \"missing\", mappings = true }] }"
reject_profile provider-with-two-backends \
  "${user_profile_value} & { secondaries.providers = [{ name = \"ambiguous\", mappings = true, local.store = \"old\", remote = { master_url = \"https://repo.example/master\", trusted_keys = [\"key.pem\"] } }] }"
reject_profile provider-without-capability \
  "${user_profile_value} & { secondaries.providers = [{ name = \"unused\", local.store = \"old\" }] }"
reject_profile provider-with-empty-name \
  "${user_profile_value} & { secondaries.providers = [{ name = \"\", mappings = true, local.store = \"old\" }] }"
reject_profile local-content-without-transfer \
  "${user_profile_value} & { secondaries.providers = [{ name = \"content\", content = true, local.store = \"old\" }] }"
reject_profile local-mappings-with-transfer \
  "${user_profile_value} & { secondaries.providers = [{ name = \"mappings\", mappings = true, local = { store = \"old\", transfer = \"hardlink\" } }] }"
reject_profile remote-without-keys \
  "${user_profile_value} & { secondaries.providers = [{ name = \"remote\", mappings = true, remote = { master_url = \"https://repo.example/master\", trusted_keys = [] } }] }"
reject_profile remote-with-transfer \
  "${user_profile_value} & { secondaries.providers = [{ name = \"remote\", content = true, remote = { master_url = \"https://repo.example/master\", trusted_keys = [\"key.pem\"], transfer = \"copy\" } }] }"
reject_profile unknown-provider-field \
  "${user_profile_value} & { secondaries.providers = [{ name = \"typo\", mappings = true, local.store = \"old\", priority = 1 }] }"
reject_profile empty-goals \
  "${profile_prelude} (import \"${recipes_path}/build-profile/bobr-user.ncl\") & { include pkgs, goals = [] }"

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
  "${user_profile_value} & (import \"${recipes_path}/build-profile/output-repo-potato.ncl\") & {
    store = \"request-store\",
    secondaries = {
      repository_cache = \"metadata-cache\",
      providers = [
        {
          name = \"previous\",
          mappings = true,
          content = true,
          local = { store = \"previous-store\", transfer = \"hardlink\" },
        },
        {
          name = \"remote-metadata\",
          mappings = true,
          content = true,
          remote = {
            master_url = \"https://repo.example/master\",
            trusted_keys = [\"keys/repository.pem\"],
            ca_bundle = \"tls/ca.pem\",
          },
        },
        {
          name = \"archive-content\",
          content = true,
          local = { store = \"archive-store\", transfer = \"copy\" },
        },
      ],
    },
  }"
PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run --target glibc_gen1 \
  "${temporary}/request.ncl" > "${temporary}/request.json" 2> "${temporary}/dry-run.log"
if grep -q 'output_repository' "${temporary}/request.json"; then
  fail "output_repository leaked into the Bobr request"
fi
jq -e --arg root "${temporary}" '
  .schema == "bobr-request-v6"
  and .secondaries.repository_cache == ($root + "/metadata-cache")
  and (.secondaries.providers | length) == 5
  and .secondaries.providers[0] == {
    name: "previous",
    capability: "mappings",
    backend: { kind: "local", store: ($root + "/previous-store") }
  }
  and .secondaries.providers[1] == {
    name: "previous",
    capability: "content",
    backend: {
      kind: "local",
      store: ($root + "/previous-store"),
      transfer: "hardlink"
    }
  }
  and .secondaries.providers[2] == {
    name: "remote-metadata",
    capability: "mappings",
    backend: {
      kind: "remote",
      master_url: "https://repo.example/master",
      trusted_keys: [$root + "/keys/repository.pem"],
      ca_bundle: ($root + "/tls/ca.pem")
    }
  }
  and .secondaries.providers[3] == {
    name: "remote-metadata",
    capability: "content",
    backend: {
      kind: "remote",
      master_url: "https://repo.example/master",
      trusted_keys: [$root + "/keys/repository.pem"],
      ca_bundle: ($root + "/tls/ca.pem")
    }
  }
  and .secondaries.providers[4] == {
    name: "archive-content",
    capability: "content",
    backend: {
      kind: "local",
      store: ($root + "/archive-store"),
      transfer: "copy"
    }
  }
' "${temporary}/request.json" >/dev/null \
  || fail "secondary providers were not resolved and normalized as expected"

# Overlays are ordinary Nickel imports relative to the user profile and retain
# their array order while constructing the final package set.
write_profile "${temporary}/overlay-one.ncl" \
  'fun final => fun prev => { selected = prev.glibc_gen1 & { name | force = "overlay-one" } }'
write_profile "${temporary}/overlay-two.ncl" \
  'fun final => fun prev => { selected_two = prev.selected }'
write_profile "${temporary}/overlay-profile.ncl" \
  "let bobrpkgs = import \"${recipes_path}/bobrpkgs.ncl\" in
   let pkgs = bobrpkgs [import \"./overlay-one.ncl\", import \"./overlay-two.ncl\"] in
   { include pkgs, goals = [pkgs.selected_two], store = \"request-store\" }"
if ! PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run \
  "${temporary}/overlay-profile.ncl" \
  > "${temporary}/overlay-request.json" 2> "${temporary}/overlay-dry-run.log"; then
  cat "${temporary}/overlay-dry-run.log" >&2
  fail "ordered profile overlays failed to lower"
fi
jq -e '.nodes.root.name == "overlay-one"' \
  "${temporary}/overlay-request.json" >/dev/null \
  || fail "ordered profile overlays were not applied"

# Repeated --target values replace the profile goals as one ordered goal list.
PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run \
  --target glibc_gen1 --target gcc_gen1 "${temporary}/request.ncl" \
  > "${temporary}/multi-request.json" 2> "${temporary}/multi-dry-run.log"
jq -e '
  [.goals[] as $id | .nodes[$id].name]
    == ["glibc-gen1-2.42", "gcc-gen1-15.2.0"]
  and (.goals | length) == 2
  and ([.nodes[].name] | length) == ([.nodes[].name] | unique | length)
' "${temporary}/multi-request.json" >/dev/null \
  || fail "ordered multi-goal CLI lowering is invalid"

duplicate_profile="${temporary}/duplicate-goals.ncl"
write_profile "${duplicate_profile}" \
  "${profile_prelude} { include pkgs, goals = [pkgs.glibc_gen1, pkgs.glibc_gen1], store = \"request-store\" }"
if PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run "${duplicate_profile}" \
  >/dev/null 2> "${temporary}/duplicate-goals.log"; then
  fail "duplicate goal recipe names were accepted"
fi
grep -F 'goal recipe names must be unique' \
  "${temporary}/duplicate-goals.log" >/dev/null \
  || { cat "${temporary}/duplicate-goals.log" >&2; fail "duplicate goals did not produce the expected diagnostic"; }

if PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run --target no_such_recipe \
  "${temporary}/request.ncl" >/dev/null 2> "${temporary}/unknown-target.log"; then
  fail "unknown CLI target was accepted"
fi
grep -F "no recipe attribute named 'no_such_recipe'" \
  "${temporary}/unknown-target.log" >/dev/null \
  || fail "unknown CLI target did not produce the expected diagnostic"

echo "test-profile.sh: all tests passed"
