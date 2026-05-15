#!/usr/bin/env bash

# Smoke-test the recipe contract and selected recipe-lib lowering behavior,
# then shallow-validate every raw recipe from pkgs.ncl.
# Run this when editing recipe contracts, pkgs wiring, or recipe shapes.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
contract_file="${repo_root}/contracts/recipe.ncl"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

run_case() {
  local name="$1"
  local expect="$2"
  local json_payload="$3"

  printf '%s\n' "${json_payload}" > "${tmpdir}/recipe.json"
  cat > "${tmpdir}/check.ncl" <<EOF_INNER
let contracts = import "${contract_file}" in
let recipe = import "./recipe.json" in
contracts.validate_recipe recipe
EOF_INNER

  if (cd "${tmpdir}" && nickel export check.ncl --format json >/dev/null 2>&1); then
    if [[ "${expect}" != "pass" ]]; then
      echo "expected failure for ${name}" >&2
      return 1
    fi
  else
    if [[ "${expect}" != "fail" ]]; then
      echo "expected success for ${name}" >&2
      return 1
    fi
  fi
}

rootfs_tree='{"name":"rootfs-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"bin"}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}}'
source_node='{"name":"src","tag":"Source","object_hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","origin":{"type":"http","url":"https://example.invalid/src.tar.xz"},"meta":{}}'
patch_node='{"name":"patch","tag":"Source","object_hash":"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","origin":{"type":"http","url":"https://example.invalid/src.patch","unpack":false},"meta":{}}'
script_node='{"name":"script","tag":"Text","config":{"source":"#!/bin/sh\n","executable":true},"inputs":{}}'

run_case "text" pass '{"name":"hello","tag":"Text","config":{"source":"hi","executable":false},"inputs":{}}'
run_case "source" pass '{"name":"script","tag":"Source","object_hash":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","origin":{"type":"path","path":"tests/script.sh","mode":"direct"},"meta":{}}'
run_case "source-cutoff" pass '{"name":"script","tag":"Source","object_hash":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","meta":{}}'
run_case "source-http-with-install" pass '{"name":"src","tag":"Source","object_hash":"1111111111111111111111111111111111111111111111111111111111111111","origin":{"type":"http","url":"https://example.invalid/src.tar.gz"},"meta":{"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}}}'
run_case "tree-file" pass '{"name":"hello-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"file","path":"hello.txt","text":"hi\n","executable":false}]}},"inputs":{}}'
run_case "tree-dir" pass '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"dev"},{"type":"file","path":"etc/hostname","text":"mbuild\n","executable":false}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}}'
run_case "tree-symlink" pass '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"usr/bin"},{"type":"symlink","path":"bin","target":"usr/bin"}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}}'
run_case "tree-merge" pass '{"name":"merged-tree","tag":"TreeMerge","config":{},"inputs":{"left":{"name":"left-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"bin"}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}},"right":{"name":"right-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"etc"}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}}}}'
run_case "source-http" pass "${source_node}"
run_case "source-oci-registry" pass '{"name":"img","tag":"Source","object_hash":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","origin":{"type":"oci-registry","image":"docker.io/library/alpine:latest","digest":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},"meta":{}}'
run_case "autotools-sandbox" pass '{"name":"pkg-sandbox","tag":"Autotools","config":{"configure_args":["--disable-nls"],"pre_configure":{"name":"patch","run_as":"build-user","argv":["patch","-p1","-i",""]},"post_install":[{"name":"fix-mode","run_as":"root","argv":["chmod","0755","/usr/bin/tool"]}]},"inputs":{"rootfs":'"${rootfs_tree}"',"source":'"${source_node}"',"patch":'"${patch_node}"'}}'
run_case "makefile-sandbox" pass '{"name":"pkg-sandbox","tag":"Makefile","config":{"make_args":["PREFIX=/usr"],"pre_build":{"name":"patch","run_as":"build-user","argv":["patch","-p1","-i",""]},"post_install":[{"name":"link","run_as":"root","argv":["ln","-svf","tool","/usr/bin/tool"]}],"skip_install":true},"inputs":{"rootfs":'"${rootfs_tree}"',"source":'"${source_node}"',"patch":'"${patch_node}"'}}'
run_case "meson-sandbox" pass '{"name":"pkg-sandbox","tag":"Meson","config":{"setup_args":["--buildtype=release"],"pre_configure":{"name":"patch","run_as":"build-user","argv":["patch","-p1","-i",""]},"post_install":[{"name":"link","run_as":"root","argv":["ln","-svf","tool","/usr/bin/tool"]}]},"inputs":{"rootfs":'"${rootfs_tree}"',"source":'"${source_node}"',"patch":'"${patch_node}"'}}'
run_case "perl-module-sandbox" pass '{"name":"pkg-sandbox","tag":"PerlModule","config":{"perl_args":["INSTALLDIRS=vendor"],"make_args":["DESTDIR=/tmp/out"],"pre_configure":{"name":"patch","run_as":"build-user","argv":["patch","-p1","-i",""]},"post_install":[{"name":"link","run_as":"root","argv":["ln","-svf","tool","/usr/bin/tool"]}]},"inputs":{"rootfs":'"${rootfs_tree}"',"source":'"${source_node}"',"patch":'"${patch_node}"'}}'
run_case "sandbox" pass '{"name":"sandbox","tag":"Sandbox","config":{"steps":[{"name":"install","run_as":"root","cwd":"/","argv":["/bin/sh","-c","true"]}]},"inputs":{"rootfs":'"${rootfs_tree}"',"script":'"${script_node}"',"source":{"name":"src-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"src"}]}},"inputs":{}}}}'
run_case "erofs-rootfs" pass '{"name":"rootfs-erofs","tag":"ErofsRootfs","config":{"compression":null,"label":null},"inputs":{"tree0":'"${rootfs_tree}"'}}'
run_case "image" pass '{"name":"img2","tag":"Image","config":{"mode":"bootstrap"},"inputs":{"in000":{"name":"tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"usr/bin"}]}},"inputs":{}}}}'
run_case "oci-extract" pass '{"name":"img-rootfs","tag":"OciExtract","config":{},"inputs":{"image":{"name":"img","tag":"Source","object_hash":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","origin":{"type":"oci-registry","image":"docker.io/library/alpine:latest","digest":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},"meta":{}}}}'

run_case "unknown-tag" fail '{"name":"bad","tag":"Demo","config":{},"inputs":{}}'
run_case "legacy-autotools-sandbox-tag" fail '{"name":"pkg","tag":"AutotoolsSandbox","config":{},"inputs":{}}'
run_case "legacy-autotools-container-tag" fail '{"name":"pkg","tag":"AutotoolsContainer","config":{},"inputs":{}}'
run_case "legacy-makefile-sandbox-tag" fail '{"name":"pkg","tag":"MakefileSandbox","config":{},"inputs":{}}'
run_case "legacy-meson-sandbox-tag" fail '{"name":"pkg","tag":"MesonSandbox","config":{},"inputs":{}}'
run_case "legacy-perl-module-sandbox-tag" fail '{"name":"pkg","tag":"PerlModuleSandbox","config":{},"inputs":{}}'
run_case "legacy-binary-tag" fail '{"name":"bin","tag":"Binary","config":{},"inputs":{}}'
run_case "legacy-container-tag" fail '{"name":"container","tag":"Container","config":{},"inputs":{}}'
run_case "legacy-ext4-rootfs-tag" fail '{"name":"rootfs","tag":"Ext4Rootfs","config":{"size_mib":256},"inputs":{}}'
run_case "legacy-rootfs-tag" fail '{"name":"rootfs-dir","tag":"Rootfs","config":{},"inputs":{}}'
run_case "tree-bad-install-shape" fail '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"dir","path":"dev"}]},"install":{"rules":[{"path":"**","attrs":{"uid":"0","gid":0}}]}},"inputs":{}}'
run_case "source-http-bad-install-shape" fail '{"name":"src","tag":"Source","object_hash":"1111111111111111111111111111111111111111111111111111111111111111","origin":{"type":"http","url":"https://example.invalid/src.tar.gz"},"meta":{"install":{"rules":[{"path":"**","attrs":{"uid":"0","gid":0}}]}}}'
run_case "tree-bad-entry-type" fail '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"pipe","path":"lib"}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}}'
run_case "tree-symlink-missing-target" fail '{"name":"runtime-tree","tag":"Tree","config":{"tree":{"entries":[{"type":"symlink","path":"lib"}]},"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{}}'
run_case "missing-sandbox-rootfs" fail '{"name":"sandbox","tag":"Sandbox","config":{"steps":[{"name":"install","run_as":"root","cwd":"/","argv":["/bin/sh","-c","true"]}]},"inputs":{"script":'"${script_node}"'}}'
run_case "sandbox-install-rejected" fail '{"name":"sandbox","tag":"Sandbox","config":{"steps":[{"name":"install","run_as":"root","cwd":"/","argv":["/bin/sh","-c","true"]}],"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{"rootfs":'"${rootfs_tree}"'}}'
run_case "autotools-sandbox-install-rejected" fail '{"name":"pkg-sandbox","tag":"Autotools","config":{"configure_args":["--disable-nls"],"install":{"rules":[{"path":"**","attrs":{"uid":0,"gid":0,"directory_mode":493,"regular_file_mode":420,"executable_file_mode":493,"symlink_mode":511}}]}},"inputs":{"rootfs":'"${rootfs_tree}"',"source":'"${source_node}"'}}'
run_case "meson-sandbox-build-dir-rejected" fail '{"name":"pkg-sandbox","tag":"Meson","config":{"build_dir":"build"},"inputs":{"rootfs":'"${rootfs_tree}"',"source":'"${source_node}"'}}'
run_case "extra-top-level-field" fail '{"name":"hello","tag":"Text","config":{"source":"hi","executable":false},"inputs":{},"extra":true}'
run_case "wrong-many-shape" fail '{"name":"img2","tag":"Image","config":{"mode":"bootstrap"},"inputs":{"base":null,"inputs":[]}}'
run_case "bad-source-http-archive-format" fail '{"name":"src","tag":"Source","object_hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","origin":{"type":"http","url":"https://example.invalid/src.tar.xz","archive_format":"tar-zst"},"meta":{}}'
run_case "bad-tree-merge-config" fail '{"name":"merged-tree","tag":"TreeMerge","config":{"base":true},"inputs":{}}'
run_case "bad-erofs-rootfs-config" fail '{"name":"rootfs-erofs","tag":"ErofsRootfs","config":{"compression":"","label":null},"inputs":{}}'

cat > "${tmpdir}/check-synthetic-lowering.ncl" <<EOF_INNER
let recipe = import "${repo_root}/recipe-lib.ncl" in
let source_src = {
  name = "src",
  tag = "Source",
  object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  origin = {
    type = "http",
    url = "https://example.invalid/src.tar.xz",
  },
  meta = {},
} in
let rootfs_tree = {
  name = "rootfs-tree",
  tag = "Tree",
  config = {
    tree = {
      entries = [{ type = "dir", path = "bin" }],
    },
  },
  inputs = {},
} in
let patch_src = {
  name = "patch-src",
  tag = "Source",
  object_hash = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
  origin = {
    type = "http",
    url = "https://example.invalid/a.patch",
    unpack = false,
  },
  meta = {},
} in
let patch_extra_src = {
  name = "patch-extra-src",
  tag = "Source",
  object_hash = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
  origin = {
    type = "http",
    url = "https://example.invalid/b.patch",
    unpack = false,
  },
  meta = {},
} in
let aux_src = {
  name = "aux-src",
  tag = "Source",
  object_hash = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
  origin = {
    type = "http",
    url = "https://example.invalid/aux.txt",
    unpack = false,
  },
  meta = {},
} in
recipe.to_request {
  name = "pkg",
  tag = "Autotools",
  config = {
    source_subdir = "subdir",
    pre_configure = {
      name = "pre",
      run_as = "build-user",
      argv = ["true"],
    },
  },
  inputs = {
    rootfs = rootfs_tree,
    source = source_src,
    patch_extra = patch_extra_src,
    patch = patch_src,
    aux = aux_src,
  },
}
EOF_INNER

synthetic_lowering_json="$(
  cd "${tmpdir}" &&
    nickel export check-synthetic-lowering.ncl --format json
)"

jq -e '
  .root.tag == "Sandbox"
  and .root.config.steps[0].name == "prepare_source"
  and .root.config.steps[0].env.MBUILD_SOURCE_INPUT == "@{source}"
  and .root.config.steps[0].env.MBUILD_SOURCE_DIR == "@{build}/source"
  and .root.config.steps[0].env.MBUILD_SYNTHETIC_COMMON == "@{synthetic_common}"
  and .root.config.steps[0].env.MBUILD_PATCH_INPUTS == "@{patch} @{patch_extra}"
  and .root.config.steps[1].cwd == "@{build}/source/subdir"
  and (.root.inputs | has("rootfs"))
  and (.root.inputs | has("script"))
  and (.root.inputs | has("synthetic_common"))
' <<<"${synthetic_lowering_json}" >/dev/null

cat > "${tmpdir}/check-meson-synthetic-lowering.ncl" <<EOF_INNER
let recipe = import "${repo_root}/recipe-lib.ncl" in
let source_src = {
  name = "src",
  tag = "Source",
  object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  origin = {
    type = "http",
    url = "https://example.invalid/src.tar.xz",
  },
  meta = {},
} in
let rootfs_tree = {
  name = "rootfs-tree",
  tag = "Tree",
  config = {
    tree = {
      entries = [{ type = "dir", path = "bin" }],
    },
  },
  inputs = {},
} in
recipe.to_request {
  name = "pkg",
  tag = "Meson",
  config = {
    source_subdir = "subdir",
    setup_args = ["--buildtype=release"],
    pre_configure = {
      name = "pre",
      run_as = "build-user",
      argv = ["true"],
    },
  },
  inputs = {
    rootfs = rootfs_tree,
    source = source_src,
  },
}
EOF_INNER

meson_synthetic_lowering_json="$(
  cd "${tmpdir}" &&
    nickel export check-meson-synthetic-lowering.ncl --format json
)"

jq -e '
  .root.tag == "Sandbox"
  and .root.config.steps[0].name == "prepare_source"
  and .root.config.steps[0].env.MBUILD_SOURCE_DIR == "@{build}/source"
  and .root.config.steps[1].cwd == "@{build}/source/subdir"
  and (.root.config.script_config | has("build_dir") | not)
' <<<"${meson_synthetic_lowering_json}" >/dev/null

cat > "${tmpdir}/list-raw-pkgs.ncl" <<EOF_INNER
let raw_pkgs = (import "${repo_root}/pkgs.ncl") [] in
std.record.fields raw_pkgs
EOF_INNER
attr_count="$(
  cd "${tmpdir}" &&
    nickel export list-raw-pkgs.ncl --format json | jq 'length'
)"

cat > "${tmpdir}/check-shallow-raw-pkgs.ncl" <<EOF_INNER
let contracts = import "${contract_file}" in
let raw_pkgs = (import "${repo_root}/pkgs.ncl") [] in
std.record.map
  (fun _ recipe => let checked = recipe | contracts.shallow_recipe in checked.tag)
  raw_pkgs
EOF_INNER

(cd "${tmpdir}" && nickel export check-shallow-raw-pkgs.ncl --format json >/dev/null)

echo "recipe contract smoke tests passed (${attr_count} raw recipes shallow-validated)"
