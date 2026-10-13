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

# Glibc implementation details stay private. Bootstrap checks must inspect the
# environment actually selected by glibc_gen1, including input-level overlays.
nickel export --format json >"${temporary}/glibc-private.json" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let patched = package_set [fun _final => fun prev => {
  glibc = prev.glibc & { inputs.patch_locale_archive | force = {
    name = "overlay-locale-patch",
    tag = "Source",
    object_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  } },
}] in
let test_case = fun renamed =>
  let replacement = {
    name = if renamed then "overlay-bootstrap-rootfs" else original.glibc_gen1.inputs._rootfs.name,
    tag = "Source",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  } in
  let pkgs = package_set [fun _final => fun prev => {
    glibc_gen1 = prev.glibc_gen1 & { inputs._rootfs | force = replacement },
  }] in
  let check = pkgs.test_bootstrap_rootfs.inputs.reports.inputs.n001 in
  {
    expected_name = replacement.name,
    check_name = check.name,
    configured_name = check.config.script_config.name,
    target_name = check.inputs._target.name,
    target_hash = if check.inputs._target.tag == "Source" then check.inputs._target.object_hash else null,
  }
in
{
  exports_rootfs = std.record.has_field "glibc_bootstrap_rootfs" original,
  exports_patch = std.record.has_field "glibc_locale_archive_patch_2_42" original,
  patch_name = patched.glibc.inputs.patch_locale_archive.name,
  patch_hash = patched.glibc.inputs.patch_locale_archive.object_hash,
  cases = [test_case false, test_case true],
}
EOF_NICKEL
jq -e '
  (.exports_rootfs | not) and (.exports_patch | not)
  and .patch_name == "overlay-locale-patch"
  and .patch_hash == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  and all(.cases[];
    .check_name == ("check-" + .expected_name)
    and .configured_name == .expected_name
    and .target_name == .expected_name
    and .target_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  )
' "${temporary}/glibc-private.json" >/dev/null

# Package-specific patches and defaults are private inputs, not standalone
# public recipes. They remain customizable through their consumer's inputs.
nickel export --format json >"${temporary}/private-sources.json" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let cases = [
  { consumer = "expect", input = "patch_gcc15", former_export = "expect_gcc15_patch" },
  { consumer = "glmark2", input = "patch_data_path_environment", former_export = "data_path_environment_patch" },
  { consumer = "kbd", input = "patch_backspace", former_export = "kbd_backspace_patch" },
  { consumer = "mc", input = "defaults", former_export = "mc_defaults" },
  { consumer = "mc", input = "patch_runtime_paths", former_export = "runtime_paths_patch" },
  { consumer = "mesa_demos", input = "patch_use_libopengl", former_export = "use_libopengl_patch" },
  { consumer = "slang", input = "patch_use_path_ln", former_export = "use_path_ln_patch" },
  { consumer = "virglrenderer", input = "patch_render_server_path", former_export = "render_server_path_patch" },
] in
let test_case = fun args => fun renamed =>
  let original_input = std.record.get args.input (std.record.get args.consumer original).inputs in
  let replacement = {
    name = if renamed then "overlay-%{args.former_export}" else original_input.name,
    tag = "Source",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    origin = { tag = "RecipePath", path = "overlay-fixture.patch" },
  } in
  let pkgs = package_set [fun _final => fun prev => {
    "%{args.consumer}" = std.record.get args.consumer prev & {
      inputs."%{args.input}" | force = replacement,
    },
  }] in
  let actual = std.record.get args.input (std.record.get args.consumer pkgs).inputs in
  {
    exported = std.record.has_field args.former_export original,
    original_tag = original_input.tag,
    expected_name = replacement.name,
    actual_name = actual.name,
    actual_tag = actual.tag,
    actual_hash = actual.object_hash,
    actual_origin = actual.origin,
  }
in
std.array.flat_map (fun args => [test_case args false, test_case args true]) cases
EOF_NICKEL
jq -e '
  length == 16 and all(.[];
    (.exported | not) and .original_tag == "Source"
    and .actual_name == .expected_name and .actual_tag == "Source"
    and .actual_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    and .actual_origin == {tag: "RecipePath", path: "overlay-fixture.patch"}
  )
' "${temporary}/private-sources.json" >/dev/null

# Target std inherits the final compiler version, but remains independently
# overridable. Changing versions still requires supplying matching source hashes.
nickel export --format json >"${temporary}/rust-std.json" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let compiler_overlay = fun _final => fun prev => {
  rust_bin = prev.rust_bin & { version = "9.8.7" },
  rust_std_native_musl = prev.rust_std_native_musl & {
    source_object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  },
} in
let summary = fun pkgs => {
  compiler_version = pkgs.rust_bin.version,
  std_version = pkgs.rust_std_native_musl.version,
  std_name = pkgs.rust_std_native_musl.name,
  source_name = pkgs.rust_std_native_musl.inputs.source.name,
  source_url = pkgs.rust_std_native_musl.inputs.source.origin.url,
  source_hash = pkgs.rust_std_native_musl.inputs.source.object_hash,
} in
{
  original = summary (package_set []),
  inherited = summary (package_set [compiler_overlay]),
  explicit = summary (package_set [compiler_overlay, fun _final => fun prev => {
    rust_std_native_musl = prev.rust_std_native_musl & { version = "8.7.6" },
  }]),
}
EOF_NICKEL
jq -e '
  .original.compiler_version == .original.std_version
  and .inherited.compiler_version == "9.8.7"
  and .inherited.std_version == "9.8.7"
  and .explicit.compiler_version == "9.8.7"
  and .explicit.std_version == "8.7.6"
  and all(.inherited, .explicit;
    .std_name == ("rust-std-native-musl-" + .std_version)
    and .source_name == ("rust-std-x86-64-unknown-linux-musl-src-" + .std_version)
    and .source_url == ("https://static.rust-lang.org/dist/rust-std-" + .std_version + "-x86_64-unknown-linux-musl.tar.xz")
    and .source_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  )
' "${temporary}/rust-std.json" >/dev/null

# Smoke tests must exercise the final public bundle, also through test_all.
# Replace only the bundle and check environment to keep lowering small.
nickel export --format json >"${temporary}/bundle-tests.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let original = package_set [] in
let cases = [
  { bundle_attr = "host_bundle_test_mesa", test_attr = "test_host_bundle_test_mesa", slot = "n000" },
  { bundle_attr = "host_bundle_qemu", test_attr = "test_host_bundle_qemu", slot = "n001" },
  { bundle_attr = "host_bundle_qemu_weston", test_attr = "test_host_bundle_qemu_weston", slot = "n002" },
  { bundle_attr = "host_bundle_qemu_gnome", test_attr = "test_host_bundle_qemu_gnome", slot = "n003" },
] in
let test_case = fun args => fun renamed =>
  let replacement = {
    name = if renamed then "overlay-%{args.bundle_attr}" else (std.record.get args.bundle_attr original).name,
    tag = "Source",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  } in
  let pkgs = package_set [fun _final => fun _prev => {
    "%{args.bundle_attr}" = replacement,
    oci_buildpack_deps_rootfs = {
      name = "fixture-check-rootfs",
      tag = "Source",
      object_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    },
  }] in
  let check = std.record.get args.test_attr pkgs in
  let parent_check = std.record.get args.slot pkgs.test_all.inputs.n000.inputs in
  {
    expected_name = replacement.name,
    actual_name = check.inputs.bundle.name,
    actual_tag = check.inputs.bundle.tag,
    parent_name = parent_check.inputs.bundle.name,
    parent_tag = parent_check.inputs.bundle.tag,
    parent_hash = if parent_check.inputs.bundle.tag == "Source" then parent_check.inputs.bundle.object_hash else null,
    config_unchanged = check.config == (std.record.get args.test_attr original).config,
    lowered = if check.inputs.bundle.tag == "Source" then
      recipe.to_request { recipes_path = "${repo_root}" } pkgs check else null,
  }
in
std.array.flat_map (fun args => [test_case args false, test_case args true]) cases
EOF_NICKEL
jq -e '
  length == 8 and all(.[];
    .actual_name == .expected_name and .actual_tag == "Source"
    and .parent_name == .expected_name and .parent_tag == "Source"
    and .parent_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    and .config_unchanged and (.lowered | length) == 4
    and .lowered[.lowered.root.inputs.bundle].name == .expected_name
    and .lowered[.lowered.root.inputs.bundle].tag == "Source"
    and .lowered[.lowered.root.inputs.bundle].object_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  )
' "${temporary}/bundle-tests.json" >/dev/null

echo "recipe overlay tests passed (library/compiler splits, runtime, initrd, aggregates, private inputs, Rust std, bundle tests)"
