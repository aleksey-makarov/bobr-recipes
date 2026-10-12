#!/usr/bin/env bash

# Targeted fixed-point wiring tests. Export only summaries and lowered graphs,
# never the complete recursively expanded package set.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

for base in acl attr glibc kmod libcap libdrm libxcrypt linux_pam ncurses \
  openssl slang systemd util_linux xz; do
  nickel export --format json >"${temporary}/split.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let test_case = fun renamed =>
  let replacement = {
    name = if renamed then "overlay-${base}-9.8.7" else original.${base}.name,
    tag = "Source",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  } in
  let pkgs = package_set [fun _final => fun _prev => { ${base} = replacement }] in
  let split = pkgs.${base}_libs in
  {
    expected_name = if renamed then "overlay-${base}-libs-9.8.7" else original.${base}_libs.name,
    expected_tree_name = replacement.name,
    name = split.name,
    tag = split.tag,
    includes = split.config.include,
    original_includes = original.${base}_libs.config.include,
    tree_name = split.inputs.tree.name,
    tree_tag = split.inputs.tree.tag,
    # Do not traverse the original build graph when the wiring is wrong.
    lowered = if split.inputs.tree.tag == "Source" then
      recipe.to_request { recipes_path = "${repo_root}" } pkgs split
    else null,
  }
in
[test_case false, test_case true]
EOF_NICKEL
  if ! jq -e '
    length == 2 and all(.[];
      .name == .expected_name and .tag == "TreeSubset"
      and .includes == .original_includes
      and .tree_tag == "Source" and .tree_name == .expected_tree_name
      and .lowered.root.name == .expected_name
      and .lowered.root.config.include == .original_includes
      and (.lowered | length) == 2
      and (.lowered[.lowered.root.inputs.tree] |
        .tag == "Source"
        and .object_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    )
  ' "${temporary}/split.json" >/dev/null; then
    echo "${base}_libs does not follow its final package-set input/name" >&2
    cat "${temporary}/split.json" >&2
    exit 1
  fi
done

# Ordinary record merges must propagate the version and source identity too.
nickel export --format json >"${temporary}/attr-version.json" <<EOF_NICKEL
let pkgs = (import "${repo_root}/bobrpkgs.ncl") [
  fun _final => fun prev => {
    attr = prev.attr & {
      version = "9.8.7",
      source_object_hash = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    },
  },
] in
{
  name = pkgs.attr_libs.name,
  tree_name = pkgs.attr_libs.inputs.tree.name,
  source_name = pkgs.attr_libs.inputs.tree.inputs.source.name,
  source_hash = pkgs.attr_libs.inputs.tree.inputs.source.object_hash,
}
EOF_NICKEL
jq -e '
  .name == "attr-libs-9.8.7" and .tree_name == "attr-9.8.7"
  and .source_name == "attr-src-9.8.7"
  and .source_hash == "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
' "${temporary}/attr-version.json" >/dev/null

# The development split must follow both the full package and the independently
# overridden library split; its name follows the full package's version.
nickel export --format json >"${temporary}/systemd-dev.json" <<EOF_NICKEL
let pkgs = (import "${repo_root}/bobrpkgs.ncl") [
  fun _final => fun _prev => {
    systemd = {
      name = "overlay-systemd-9.8.7",
      version = "9.8.7",
      tag = "Source",
      object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    },
    systemd_libs = {
      name = "overlay-systemd-libs-9.8.7",
      tag = "Source",
      object_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    },
  },
] in
{
  name = pkgs.systemd_dev.name,
  tree_name = pkgs.systemd_dev.inputs.tree.name,
  tree_hash = if pkgs.systemd_dev.inputs.tree.tag == "Source" then
    pkgs.systemd_dev.inputs.tree.object_hash else null,
  runtime = std.array.map (fun dependency => dependency.name) pkgs.systemd_dev.deps.runtime,
}
EOF_NICKEL
jq -e '
  .name == "systemd-dev-9.8.7"
  and .tree_name == "overlay-systemd-9.8.7"
  and .tree_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  and .runtime == ["overlay-systemd-libs-9.8.7"]
' "${temporary}/systemd-dev.json" >/dev/null

# Compiler splits follow the final GCC, including its version; bootstrap GCC
# remains independent. Inspect and lower only the selected split graphs.
nickel export --format json >"${temporary}/gcc-splits.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let test_case = fun renamed =>
  let version = if renamed then "9.8.7" else original.gcc.version in
  let replacement = {
    include version,
    name = if renamed then "overlay-gcc-9.8.7" else original.gcc.name,
    tag = "Source",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  } in
  let pkgs = package_set [fun _final => fun _prev => { gcc = replacement }] in
  {
    bootstrap_unchanged = pkgs.gcc_gen1.name == original.gcc_gen1.name
      && pkgs.gcc_gen1.inputs.source.object_hash == original.gcc_gen1.inputs.source.object_hash,
    runtime_name = pkgs.c_runtime.name,
    expected_runtime_name = "c-runtime-%{original.glibc.name}-%{version}",
    splits = std.array.map
      (fun suffix =>
        let split = std.record.get ("gcc_" ++ suffix) pkgs in
        {
          expected_name = "gcc-%{suffix}-%{version}",
          name = split.name,
          expected_tree_name = replacement.name,
          tree_name = split.inputs.tree.name,
          original_includes = (std.record.get ("gcc_" ++ suffix) original).config.include,
          lowered = if split.inputs.tree.tag == "Source" then
            recipe.to_request { recipes_path = "${repo_root}" } pkgs split
          else null,
        }
      )
      ["libgcc", "libstdcxx", "libgomp"],
  }
in
[test_case false, test_case true]
EOF_NICKEL
jq -e '
  length == 2 and all(.[];
    .bootstrap_unchanged and .runtime_name == .expected_runtime_name
    and all(.splits[];
      .name == .expected_name and .tree_name == .expected_tree_name
      and .lowered.root.name == .expected_name
      and .lowered.root.config.include == .original_includes
      and (.lowered | length) == 2
      and (.lowered[.lowered.root.inputs.tree] |
        .tag == "Source"
        and .object_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    )
  )
' "${temporary}/gcc-splits.json" >/dev/null

# Overriding the runtime and its individual components are independent knobs.
nickel export --format json >"${temporary}/gcc-runtime.json" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let source = fun name => fun hash => { include name, tag = "Source", object_hash = hash } in
let component_pkgs = package_set [fun _final => fun _prev => {
  gcc_libgcc = source "overlay-libgcc" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  glibc_libs = source "overlay-glibc-libs" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
}] in
let runtime_pkgs = package_set [fun _final => fun _prev => {
  c_runtime = source "overlay-c-runtime" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
}] in
{
  components = std.record.map (fun _ node => {
    name = node.name,
    hash = if node.tag == "Source" then node.object_hash else null,
  }) component_pkgs.c_runtime.inputs,
  libgcc_runtime = std.array.map (fun node => node.name) runtime_pkgs.gcc_libgcc.deps.runtime,
  expected_libgcc_runtime = [runtime_pkgs.glibc_libs.name],
  runtime = std.array.map (fun attr => std.array.map (fun node => {
    name = node.name,
    hash = if node.tag == "Source" then node.object_hash else null,
  }) (std.record.get attr runtime_pkgs).deps.runtime) ["gcc_libstdcxx", "gcc_libgomp"],
}
EOF_NICKEL
jq -e '
  .components == {
    glibc: {name: "overlay-glibc-libs", hash: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},
    libgcc: {name: "overlay-libgcc", hash: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
  }
  and .libgcc_runtime == .expected_libgcc_runtime
  and all(.runtime[]; . == [{name: "overlay-c-runtime", hash: "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}])
' "${temporary}/gcc-runtime.json" >/dev/null

# Cut the aggregate at each public input to test order and lowered references
# without serializing the unrelated build branches. Test both retained and new
# recipe names, including checks hidden behind an internal report Bundle.
nickel export --format json >"${temporary}/aggregates.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let source = fun name => {
  include name,
  tag = "Source",
  object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
} in
let cases = [
  { target = "world", children = ["os_world", "host_bundle_world"] },
  { target = "os_world", children = ["linux", "initrd", "qemu_image", "qemu_weston_image", "qemu_gnome_image"] },
  { target = "host_bundle_world", children = ["bobr_bundle_launcher", "host_bundle_mc", "host_bundle_test_mesa", "host_bundle_qemu", "host_bundle_qemu_weston", "host_bundle_qemu_gnome"] },
  { target = "test_all", children = ["test_host_bundles", "test_runtime_closures", "test_bootstrap_rootfs", "test_image_rootfs", "test_final_toolchain"] },
  { target = "test_host_bundles", children = ["test_host_bundle_test_mesa", "test_host_bundle_qemu", "test_host_bundle_qemu_weston", "test_host_bundle_qemu_gnome"] },
  { target = "test_image_rootfs", children = ["test_initrd_rootfs", "test_rootfs", "test_weston_rootfs", "test_gnome_rootfs"] },
  { target = "initrd", children = ["initrd_rootfs"] },
] in
let test_case = fun args => fun renamed =>
  let expected_names = std.array.map (fun attr =>
    if renamed then "overlay-%{attr}" else (std.record.get attr original).name) args.children in
  let pkgs = package_set [fun _final => fun _prev =>
    std.record.from_array (std.array.map_with_index (fun index => fun attr => {
      field = attr, value = source (std.array.at index expected_names),
    }) args.children)
    & {
      # Small packing/check environments, not the full bootstrap graph.
      base_filesystem = source "fixture-base-filesystem",
      gen_init_cpio = source "fixture-gen-init-cpio",
      bash = source "fixture-bash",
      coreutils = source "fixture-coreutils",
      findutils = source "fixture-findutils",
      oci_buildpack_deps_rootfs = source "fixture-check-rootfs",
    }
  ] in
  let goal_node = std.record.get args.target pkgs in
  let inputs = if args.target == "test_image_rootfs" then goal_node.inputs.reports.inputs
    else if args.target == "initrd" then { tree = goal_node.inputs._tree }
    else goal_node.inputs in
  let followed = std.record.map (fun _ node => node.tag == "Source") inputs in
  let correct = std.array.all (fun slot => std.record.get slot followed) (std.record.fields followed) in
  {
    target = args.target,
    include expected_names,
    actual_names = std.array.map (fun slot => (std.record.get slot inputs).name) (std.record.fields inputs),
    include correct,
    lowered = if correct then recipe.to_request { recipes_path = "${repo_root}" } pkgs goal_node else null,
    # Follow the same leaf override through the public parent aggregate too.
    parent_names = if args.target == "test_image_rootfs" then
      std.array.map (fun slot => (std.record.get slot pkgs.test_all.inputs.n003.inputs.reports.inputs).name)
        (std.record.fields pkgs.test_all.inputs.n003.inputs.reports.inputs)
    else [],
  }
in
std.array.flat_map (fun args => [test_case args false, test_case args true]) cases
EOF_NICKEL
jq -e '
  length == 14 and all(.[];
    .correct and .actual_names == .expected_names
    and (if .target == "test_image_rootfs" then .parent_names == .expected_names else true end)
    and ([.lowered[] | select(.tag == "Source") | .name] as $sources |
      all(.expected_names[]; . as $name | ($sources | index($name)) != null))
    and (if .target == "initrd" then
      .lowered[.lowered.root.inputs._tree].tag == "Source"
      and .lowered[.lowered.root.inputs._tree].name == .expected_names[0]
    elif .target == "test_image_rootfs" then
      .lowered[.lowered.root.inputs.reports].inputs as $inputs |
      . as $case | [$inputs | to_entries[] | $case.lowered[.value].name] == .expected_names
    else
      . as $case | [.lowered.root.inputs | to_entries[] | $case.lowered[.value].name] == .expected_names
    end)
  )
' "${temporary}/aggregates.json" >/dev/null

echo "recipe overlay tests passed (library/compiler splits, runtime, initrd, aggregates)"
