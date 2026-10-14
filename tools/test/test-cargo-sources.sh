#!/usr/bin/env bash

# Check public Cargo source/vendor pairs and explicit crates inputs.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/positive.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let cases = [
  {
    label = "bobr-bundle-launcher",
    source = "bobr_bundle_launcher_src",
    crates = "bobr_bundle_launcher_crates",
    builder = "bobr_bundle_launcher",
    source_prefix = "bobr-bundle-launcher-src-",
    crates_prefix = "bobr-bundle-launcher-",
    crates_suffix = "-crates",
    builder_prefix = "bobr-bundle-launcher-",
    custom_preflight = false,
  },
  {
    label = "bindgen",
    source = "bindgen_src",
    crates = "bindgen_crates",
    builder = "bindgen",
    source_prefix = "bindgen-src-",
    crates_prefix = "bindgen-",
    crates_suffix = "-crates",
    builder_prefix = "bindgen-",
    custom_preflight = false,
  },
  {
    label = "cbindgen",
    source = "cbindgen_src",
    crates = "cbindgen_crates",
    builder = "cbindgen",
    source_prefix = "cbindgen-src-",
    crates_prefix = "cbindgen-",
    crates_suffix = "-crates",
    builder_prefix = "cbindgen-",
    custom_preflight = false,
  },
  {
    label = "glycin",
    source = "glycin_src",
    crates = "glycin_crates",
    builder = "glycin",
    source_prefix = "glycin-src-",
    crates_prefix = "glycin-crates-",
    crates_suffix = "",
    builder_prefix = "glycin-",
    custom_preflight = true,
  },
  {
    label = "librsvg",
    source = "librsvg_src",
    crates = "librsvg_crates",
    builder = "librsvg",
    source_prefix = "librsvg-src-",
    crates_prefix = "librsvg-crates-",
    crates_suffix = "",
    builder_prefix = "librsvg-",
    custom_preflight = false,
  },
] in
let original_packages = package_set [] in
let changed_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in
let coordinated_overlay = fun _final => fun prev =>
  std.record.from_array (
    std.array.flat_map
      (fun spec => [
        {
          field = spec.source,
          value = std.record.get spec.source prev & {
            version = "9.8.7",
            object_hash = changed_hash,
          },
        },
        {
          field = spec.crates,
          value = std.record.get spec.crates prev & { version = "9.8.7" },
        },
      ])
      cases
  )
in
let replacement_overlay = fun _final => fun prev =>
  std.record.from_array (
    std.array.flat_map
      (fun spec =>
        let source = std.record.get spec.source prev in
        let crates = std.record.get spec.crates prev in
        [
          {
            field = spec.source,
            value = {
              version = source.version,
              name = "replacement-%{spec.label}-source",
              tag = "Source",
              object_hash = changed_hash,
              origin = { tag = "Http", url = "https://example.invalid/%{spec.label}.tar.xz" },
            },
          },
          {
            field = spec.crates,
            value = {
              version = crates.version,
              cargo_lock = crates.cargo_lock,
              name = "replacement-%{spec.label}-crates",
              tag = "Bundle",
              config = {},
              inputs = crates.inputs,
            },
          },
        ]
      )
      cases
  )
in
let origin_overlay = fun _final => fun prev =>
  std.record.from_array (
    std.array.map
      (fun spec => {
        field = spec.source,
        value = std.record.get spec.source prev & {
          origin | force = {
            tag = "Http",
            url = "https://example.invalid/%{spec.label}.tar.xz",
          },
        },
      })
      cases
  )
in
let summarize = fun packages =>
  let goals = std.array.map (fun spec => std.record.get spec.builder packages) cases in
  let graph = recipe.to_request_goals { recipes_path = "${repo_root}" } packages goals in
  std.array.map_with_index
    (fun index => fun spec =>
      let source = std.record.get spec.source packages in
      let crates = std.record.get spec.crates packages in
      let builder = std.record.get spec.builder packages in
      let lowered = std.record.get (std.array.at index graph.goals) graph.nodes in
      let lowered_source = std.record.get lowered.inputs.source graph.nodes in
      let lowered_crates = std.record.get lowered.inputs.crates graph.nodes in
      let step_names = std.array.map (fun step => step.name) lowered.config.steps in
      let preflight_steps =
        std.array.filter
          (fun step => step.name == "bobr_verify_cargo_lock")
          lowered.config.steps
      in
      {
        label = spec.label,
        version = source.version,
        source_name = source.name,
        source_url = source.origin.url,
        crates_name = crates.name,
        builder_name = builder.name,
        crate_count = std.array.length (std.record.fields crates.inputs),
        builder_has_legacy_fields =
          std.record.has_field "version" builder
          || std.record.has_field "source_object_hash" builder
          || std.record.has_field "cargo_lock" builder,
        raw_inputs_are_public =
          builder.inputs.source == source
          && builder.inputs.crates == crates,
        lowered_inputs_are_explicit =
          lowered_source.name == source.name
          && lowered_source.object_hash == source.object_hash
          && lowered_crates.name == crates.name,
        names_follow_version =
          source.name == spec.source_prefix ++ source.version
          && crates.name == spec.crates_prefix ++ source.version ++ spec.crates_suffix
          && builder.name == spec.builder_prefix ++ source.version,
        has_expected_preflight =
          if spec.custom_preflight then
            std.array.length preflight_steps == 1
            && (std.array.at 0 preflight_steps).cwd == "@{build}/source"
            && (std.array.at 0 preflight_steps).argv == [
              "/bin/sh",
              "-ec",
              "cargo metadata --format-version 1 --locked --offline >/dev/null",
            ]
          else
            !std.array.elem "bobr_verify_cargo_lock" step_names,
      }
    )
    cases
in
let replacement_packages = package_set [replacement_overlay] in
let replacement_goals = std.array.map (fun spec => std.record.get spec.builder replacement_packages) cases in
let replacement_graph =
  recipe.to_request_goals
    { recipes_path = "${repo_root}" }
    replacement_packages
    replacement_goals
in
let replacement_checks =
  std.array.map_with_index
    (fun index => fun spec =>
      let source = std.record.get spec.source replacement_packages in
      let crates = std.record.get spec.crates replacement_packages in
      let builder = std.record.get spec.builder replacement_packages in
      let lowered = std.record.get (std.array.at index replacement_graph.goals) replacement_graph.nodes in
      {
        label = spec.label,
        correct =
          source.name == "replacement-%{spec.label}-source"
          && crates.name == "replacement-%{spec.label}-crates"
          && builder.inputs.source == source
          && builder.inputs.crates == crates
          && (std.record.get lowered.inputs.source replacement_graph.nodes).name == source.name
          && (std.record.get lowered.inputs.crates replacement_graph.nodes).name == crates.name,
      }
    )
    cases
in
let direct_crates_packages = package_set [fun _final => fun prev => {
  bindgen = prev.bindgen & {
    inputs = prev.bindgen.inputs & {
      crates | force = prev.bindgen_crates & { name | force = "bindgen-explicit-crates" },
    },
  },
}]
in
let direct_graph =
  recipe.to_request
    { recipes_path = "${repo_root}" }
    direct_crates_packages
    direct_crates_packages.bindgen
in
{
  original = summarize original_packages,
  coordinated = summarize (package_set [coordinated_overlay]),
  origin = summarize (package_set [origin_overlay]),
  replacements = replacement_checks,
  direct_crates = {
    raw = direct_crates_packages.bindgen.inputs.crates.name,
    lowered = (std.record.get direct_graph.root.inputs.crates direct_graph).name,
  },
}
EOF_NICKEL

jq -e '
  def valid:
    .crate_count > 0
    and (.builder_has_legacy_fields | not)
    and .raw_inputs_are_public
    and .lowered_inputs_are_explicit
    and .names_follow_version
    and .has_expected_preflight;
  ([.original[], .coordinated[]] | all(valid))
  and (.coordinated | all(.version == "9.8.7"))
  and (.origin | all(.source_url == "https://example.invalid/" + .label + ".tar.xz"))
  and (.replacements | all(.correct))
  and .direct_crates.raw == "bindgen-explicit-crates"
  and .direct_crates.lowered == "bindgen-explicit-crates"
' "${temporary}/positive.json" >/dev/null

while read -r source builder label; do
  if nickel export --format json >"${temporary}/${label}.json" 2>"${temporary}/${label}.log" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let packages = package_set [fun _final => fun prev =>
  std.record.from_array [{
    field = "${source}",
    value = std.record.get "${source}" prev & {
      version = "9.8.7",
      object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    },
  }]
] in
(std.record.get "${builder}" packages).name
EOF_NICKEL
  then
    echo "Cargo Source tests: ${label} accepted mismatched source/crates versions" >&2
    exit 1
  fi
  rg -F "must match vendored crates version" "${temporary}/${label}.log" >/dev/null
done <<'EOF_CASES'
bobr_bundle_launcher_src bobr_bundle_launcher bobr-bundle-launcher
bindgen_src bindgen bindgen
cbindgen_src cbindgen cbindgen
glycin_src glycin glycin
librsvg_src librsvg librsvg
EOF_CASES

echo "Cargo Source tests passed (5 public source/vendor pairs)"
