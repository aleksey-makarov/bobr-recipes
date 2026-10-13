#!/usr/bin/env bash

# Check the version-coupled libclc, LLVM toolchain, and SPIR-V translator.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/positive.json" <<EOF_NICKEL
let recipe = import "${repo_root}/recipe-lib.ncl" in
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let source = fun name => fun version => fun hash => {
  include name,
  include version,
  tag = "Source",
  object_hash = hash,
  origin = { tag = "Http", url = "https://example.invalid/%{name}.tar.xz" },
} in
let summary = fun packages =>
  let target = packages.libclc in
  let graph = recipe.to_request { recipes_path = "${repo_root}" } packages target in
  {
    name = packages.libclc.name,
    source = packages.libclc.inputs.source,
    llvm_version = packages.llvm_bin.inputs.source.version,
    llvm_name = packages.llvm_bin.name,
    llvm_install_script = (std.array.at 1 packages.llvm_bin.config.steps).argv |> std.array.at 2,
    translator_version = packages.spirv_llvm_translator.inputs.source.version,
    translator_name = packages.spirv_llvm_translator.name,
    cmake_args = packages.libclc.config.cmake_args,
    post_install_script = packages.libclc.config.post_install.argv |> std.array.at 2,
    lowered_name = graph.root.name,
    lowered_source = std.record.get graph.root.inputs.source graph,
  }
in
let default_packages = package_set [] in
{
  original = summary default_packages,
  hash_origin = summary (package_set [fun _final => fun prev => {
    libclc_src = prev.libclc_src & {
      object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      origin | force = { tag = "Http", url = "https://example.invalid/libclc.tar.xz" },
    },
  }]),
  coordinated = summary (package_set [fun _final => fun prev => {
    libclc_src = source "libclc-src-23.4.1" "23.4.1" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    llvm_bin_src = source "llvm-bin-src-23.4.1" "23.4.1" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    spirv_llvm_translator_src = source "spirv-llvm-translator-src-23.4.9" "23.4.9" "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
  }]),
  input_replacement = summary (package_set [fun _final => fun prev => {
    libclc = prev.libclc & {
      inputs.source | force = source "custom-libclc-source" "22.1.8" "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    },
  }]),
}
EOF_NICKEL

jq -e '
  .original.name == "libclc-22.1.8"
  and .original.source.name == "libclc-src-22.1.8"
  and .original.llvm_version == "22.1.8"
  and .original.translator_version == "22.1.4"
  and (.original.cmake_args | index("-DLLVM_PACKAGE_VERSION=22.1.8")) != null
  and (.original.post_install_script | contains("/usr/lib/clang/22/lib/libclc"))
  and (.original.llvm_install_script | contains("clang-22"))
  and .original.lowered_name == .original.name
  and .original.lowered_source.object_hash == .original.source.object_hash
  and .hash_origin.name == .original.name
  and .hash_origin.source.object_hash == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  and .hash_origin.source.origin.url == "https://example.invalid/libclc.tar.xz"
  and .hash_origin.lowered_source.object_hash == .hash_origin.source.object_hash
  and .coordinated.name == "libclc-23.4.1"
  and .coordinated.source.name == "libclc-src-23.4.1"
  and .coordinated.llvm_version == "23.4.1"
  and .coordinated.llvm_name == "llvm-bin-23.4.1"
  and .coordinated.translator_version == "23.4.9"
  and .coordinated.translator_name == "spirv-llvm-translator-23.4.9"
  and (.coordinated.cmake_args | index("-DLLVM_PACKAGE_VERSION=23.4.1")) != null
  and (.coordinated.post_install_script | contains("/usr/lib/clang/23/lib/libclc"))
  and (.coordinated.llvm_install_script | contains("clang-23"))
  and .coordinated.lowered_name == .coordinated.name
  and .coordinated.lowered_source.object_hash == .coordinated.source.object_hash
  and .input_replacement.name == "libclc-22.1.8"
  and .input_replacement.source.name == "custom-libclc-source"
  and .input_replacement.lowered_source.object_hash == "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
' "${temporary}/positive.json" >/dev/null

if nickel export --format json >"${temporary}/mismatched-llvm.json" 2>"${temporary}/mismatched-llvm.log" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let pkgs = package_set [fun _final => fun prev => {
  libclc_src = prev.libclc_src & {
    version = "22.1.9",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  },
}] in
pkgs.libclc.name
EOF_NICKEL
then
  echo "libclc accepted a source version different from the LLVM toolchain" >&2
  exit 1
fi
rg -F "must match LLVM toolchain version" "${temporary}/mismatched-llvm.log" >/dev/null

if nickel export --format json >"${temporary}/mismatched-translator.json" 2>"${temporary}/mismatched-translator.log" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let pkgs = package_set [fun _final => fun prev => {
  libclc_src = prev.libclc_src & {
    version = "23.4.1",
    object_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  },
  llvm_bin_src = prev.llvm_bin_src & {
    version = "23.4.1",
    object_hash = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  },
}] in
pkgs.libclc.name
EOF_NICKEL
then
  echo "libclc accepted a mismatched SPIR-V translator release series" >&2
  exit 1
fi
rg -F "must match SPIR-V translator release series" "${temporary}/mismatched-translator.log" >/dev/null

echo "libclc Source tests passed (coupled LLVM versions and derived paths)"
