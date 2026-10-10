#!/usr/bin/env bash
# `resolve_profile` in the sourced library assigns the profile_* test values;
# single-quoted strings below deliberately generate a fake executable.
# shellcheck disable=SC2016,SC2154

set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/../.." && pwd)"
tool="test-profile.sh"
# shellcheck source=profiles/profile-lib.sh
. "${recipes_path}/profiles/profile-lib.sh"

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
user_profile_value="${profile_prelude} (import \"${recipes_path}/profiles/bobr-user.ncl\") & { include pkgs, goals = [pkgs.world] }"

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
  "${user_profile_value} & (import \"${recipes_path}/profiles/publish-potato.ncl\") & { store = \"potato-store\" }"
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

hetzner_profile="${temporary}/hetzner.ncl"
write_profile "${hetzner_profile}" \
  "${user_profile_value} & (import \"${recipes_path}/profiles/publish-hetzner.ncl\") & { store = \"hetzner-store\" }"
resolve_profile "${hetzner_profile}"
assert_equal "1" "${profile_output_repository_enabled}" "Hetzner publication enabled"
assert_equal "0" "${profile_output_repository_create_bucket_if_missing}" "existing Hetzner bucket"
assert_equal "s3://bobr" "${profile_output_repository_repository}" "Hetzner repository"
assert_equal "https://nbg1.your-objectstorage.com" "${profile_output_repository_endpoint_url}" "Hetzner endpoint"
assert_equal "nbg1" "${profile_output_repository_region}" "Hetzner region"
assert_equal "bobr-hetzner" "${profile_output_repository_credentials_profile}" "Hetzner credentials profile"
assert_equal "${temporary}/.config/bobr/aws-credentials" "${profile_output_repository_credentials_file}" "Hetzner credentials path"
assert_equal "" "${profile_output_repository_ca_bundle}" "publicly trusted Hetzner TLS"
assert_equal "https://bobr.nbg1.your-objectstorage.com/master" "${profile_output_repository_master_url}" "Hetzner master URL"
assert_equal "https://bobr.nbg1.your-objectstorage.com/" "${profile_output_repository_data_base_url}" "Hetzner data URL"
assert_equal "${recipes_path}/signing-key-1.pub.pem" "${profile_output_repository_trusted_keys[0]}" "Hetzner signing key"
assert_equal "${temporary}/hetzner-store/repository-cache" "${profile_output_repository_cache}" "Hetzner cache"

hetzner_override="${temporary}/hetzner-override.ncl"
write_profile "${hetzner_override}" \
  "${user_profile_value} & (import \"${recipes_path}/profiles/publish-hetzner.ncl\") & { output_repository.credentials_file = \"private/keys\", output_repository.create_bucket_if_missing = true }"
resolve_profile "${hetzner_override}"
assert_equal "${temporary}/private/keys" "${profile_output_repository_credentials_file}" "Hetzner credentials override"
assert_equal "1" "${profile_output_repository_create_bucket_if_missing}" "Hetzner initialization override"
assert_equal "https://bobr.nbg1.your-objectstorage.com/master" "${profile_output_repository_master_url}" "Hetzner URL preserved after override"

# Reader presets are single provider entries. Normal merges override their
# low-priority capabilities/backend fields without enabling publication.
for preset in hetzner potato; do
  case "${preset}" in
    hetzner)
      expected_master="https://bobr.nbg1.your-objectstorage.com/master"
      expected_ca=""
      ;;
    potato)
      expected_master="https://192.168.0.169:7070/bobr/master"
      expected_ca="${temporary}/.config/bobr/local-repository-ca.cert.pem"
      ;;
  esac
  for capabilities in both mappings content; do
    expected_mappings=true
    expected_content=true
    override='{}'
    case "${capabilities}" in
      mappings) override='{ content = false }'; expected_content=false ;;
      content) override='{ mappings = false }'; expected_mappings=false ;;
    esac
    reader_profile="${temporary}/${preset}-${capabilities}.ncl"
    write_profile "${reader_profile}" \
      "${user_profile_value} & { secondaries.providers = [(import \"${recipes_path}/profiles/provider-${preset}.ncl\") & ${override}] }"
    resolve_profile "${reader_profile}"
    assert_equal "0" "${profile_output_repository_enabled}" "reader preset must not enable publication"
    reader_json="$(printf '%s\n' "${profile_secondaries}" | nickel export --format json)"
    jq -e --arg root "${temporary}" --arg name "${preset}" \
      --arg master "${expected_master}" --arg ca "${expected_ca}" \
      --argjson mappings "${expected_mappings}" --argjson content "${expected_content}" '
      .repository_cache == ($root + "/bobr-store/repository-cache")
      and (.providers | length) == 1
      and .providers[0] == {
        name: $name, mappings: $mappings, content: $content,
        remote: {
          master_url: $master, ca_bundle: $ca,
          trusted_keys: [$root + "/bobr-recipes/signing-key-1.pub.pem"]
        }
      }
    ' <<<"${reader_json}" >/dev/null || fail "invalid ${preset} ${capabilities} provider preset"
  done
  reject_profile "${preset}-disabled-provider" \
    "${user_profile_value} & { secondaries.providers = [(import \"${recipes_path}/profiles/provider-${preset}.ncl\") & { mappings = false, content = false }] }"

  write_profile "${reader_profile}" \
    "${user_profile_value} & { secondaries.providers = [(import \"${recipes_path}/profiles/provider-${preset}.ncl\") & { name = \"custom\", remote = { master_url = \"https://custom.example/master\", trusted_keys = [\"custom/key.pem\"], ca_bundle = \"custom/ca.pem\" } }] }"
  resolve_profile "${reader_profile}"
  reader_json="$(printf '%s\n' "${profile_secondaries}" | nickel export --format json)"
  jq -e --arg root "${temporary}" '
    .providers[0].name == "custom"
    and .providers[0].mappings and .providers[0].content
    and .providers[0].remote == {
      master_url: "https://custom.example/master",
      trusted_keys: [$root + "/custom/key.pem"], ca_bundle: ($root + "/custom/ca.pem")
    }
  ' <<<"${reader_json}" >/dev/null || fail "provider backend overrides were not resolved"
done

layered_profile="${temporary}/layered.ncl"
write_profile "${layered_profile}" \
  "${user_profile_value} & (import \"${recipes_path}/profiles/publish-potato.ncl\") & { fetch.per_host_default = 3, output_repository.create_bucket_if_missing = false }"
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
  "${profile_prelude} (import \"${recipes_path}/profiles/bobr-user.ncl\") & { include pkgs, goals = [] }"

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
  "${user_profile_value} & (import \"${recipes_path}/profiles/publish-potato.ncl\") & {
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
if ! PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run --target glibc_gen1 \
  "${temporary}/request.ncl" > "${temporary}/request.json" 2> "${temporary}/dry-run.log"; then
  cat "${temporary}/dry-run.log" >&2
  fail "secondary provider profile failed to lower"
fi
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

# The real wrapper lowers the two reader presets as four independent ordered
# capabilities, with the same backend used for both capabilities of each repo.
write_profile "${temporary}/preset-request.ncl" \
  "${user_profile_value} & {
    store = \"request-store\",
    secondaries.providers = [
      import \"${recipes_path}/profiles/provider-hetzner.ncl\",
      import \"${recipes_path}/profiles/provider-potato.ncl\",
    ],
  }"
if ! PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run --target glibc_gen1 \
  "${temporary}/preset-request.ncl" > "${temporary}/preset-request.json" \
  2> "${temporary}/preset-dry-run.log"; then
  cat "${temporary}/preset-dry-run.log" >&2
  fail "reader presets failed to lower"
fi
jq -e --arg root "${temporary}" '
  [.secondaries.providers[] | [.name, .capability]] == [
    ["hetzner", "mappings"], ["hetzner", "content"],
    ["potato", "mappings"], ["potato", "content"]
  ]
  and .secondaries.providers[0].backend == .secondaries.providers[1].backend
  and .secondaries.providers[2].backend == .secondaries.providers[3].backend
  and .secondaries.providers[0].backend == {
    kind: "remote", master_url: "https://bobr.nbg1.your-objectstorage.com/master",
    trusted_keys: [$root + "/bobr-recipes/signing-key-1.pub.pem"]
  }
  and .secondaries.providers[2].backend == {
    kind: "remote", master_url: "https://192.168.0.169:7070/bobr/master",
    trusted_keys: [$root + "/bobr-recipes/signing-key-1.pub.pem"],
    ca_bundle: ($root + "/.config/bobr/local-repository-ca.cert.pem")
  }
  and (has("output_repository") | not)
' "${temporary}/preset-request.json" >/dev/null \
  || fail "reader preset capabilities/backend configuration were not lowered correctly"

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
if ! PATH="${temporary}/bin:${PATH}" \
  "${recipes_path}/bin/bobr-build.sh" --dry-run \
  --target glibc_gen1 --target gcc_gen1 "${temporary}/request.ncl" \
  > "${temporary}/multi-request.json" 2> "${temporary}/multi-dry-run.log"; then
  cat "${temporary}/multi-dry-run.log" >&2
  fail "ordered multi-goal profile failed to lower"
fi
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
