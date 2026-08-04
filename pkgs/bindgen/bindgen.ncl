# bindgen-cli is a build-only command used by Mesa's Rust NVK code. Its exact
# crate dependency graph is vendored from the upstream release lockfile by the
# generic Cargo builder.

fun pkgs =>
  let bindgen_src = fun version => fun hash => {
    name = "bindgen-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://static.crates.io/crates/bindgen-cli/bindgen-cli-%{version}.crate",
    },
  }
  in

  let bindgen = {
    version | default = "0.72.1",
    source_object_hash
      | default
      = "8a408c0fcb20bf7bd4ceaf4bf990e223e3543a04b84d2394f3edeee29a0e87e2",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "bindgen-%{version}",
    tag = "Cargo",
    config = {},
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        # clang-sys loads libclang at runtime.
        pkgs.llvm_bin,
      ],
    },
    inputs = {
      source = bindgen_src version source_object_hash,
    },
  }
  in

  {
    include [
      bindgen,
    ],
  }
