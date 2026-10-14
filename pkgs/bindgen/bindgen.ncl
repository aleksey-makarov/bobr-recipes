# bindgen-cli is a build-only command used by Mesa's Rust NVK code. Its exact
# crate dependency graph is vendored from the upstream release lockfile by the
# generic Cargo builder.
let cargo = import "../../cargo.ncl" in
fun pkgs =>
  let matching_version = cargo.matching_version "bindgen" in

  let bindgen_src = {
    version | default = "0.72.1",
    name = "bindgen-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "8a408c0fcb20bf7bd4ceaf4bf990e223e3543a04b84d2394f3edeee29a0e87e2",
    origin = {
      tag = "Http",
      url = "https://static.crates.io/crates/bindgen-cli/bindgen-cli-%{version}.crate",
    },
  }
  in

  let bindgen_crates = {
    version | default = "0.72.1",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "bindgen-%{version}-crates",
    tag = "Bundle",
    config = {},
    inputs = cargo.vendor_inputs cargo_lock,
  }
  in

  let bindgen = {
    name = "bindgen-%{matching_version inputs.source.version inputs.crates.version}",
    tag = "Cargo",
    config = {},
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        # clang-sys loads libclang at runtime.
        pkgs.llvm_bin,
      ],
    },
    inputs = {
      source = pkgs.bindgen_src,
      crates = pkgs.bindgen_crates,
    },
  }
  in

  {
    include [
      bindgen_src,
      bindgen_crates,
      bindgen,
    ],
  }
