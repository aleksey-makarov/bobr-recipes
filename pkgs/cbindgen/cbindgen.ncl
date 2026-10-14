# cbindgen -- generates C/C++ headers from Rust. A BUILD tool only (mozjs/
# SpiderMonkey runs it to produce headers for its Rust bits); it never ships in
# a runtime rootfs. A plain cargo binary, so it uses the `Cargo` synthetic
# builder: the builder assembles the build rootfs (base_filesystem + toolchain +
# rust_bin), vendors the crates offline from Cargo.lock, and `cargo install`s the
# binary. The public source and vendored-crates recipes are a coupled pair: a
# version update must replace both so the offline dependency set matches the
# Cargo.lock shipped by the selected source.
let cargo = import "../../cargo.ncl" in
fun pkgs =>
  let matching_version = cargo.matching_version "cbindgen" in

  let cbindgen_src = {
    version | default = "0.29.4",
    name = "cbindgen-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "2ecb53484c9c167ba674026b656d8a27d7657a58e6066aa902bfb1a4aa00ae20",
    origin = {
      tag = "Http",
      url = "https://static.crates.io/crates/cbindgen/cbindgen-%{version}.crate",
    },
  }
  in

  let cbindgen_crates = {
    version | default = "0.29.4",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "cbindgen-%{version}-crates",
    tag = "Bundle",
    config = {},
    inputs = cargo.vendor_inputs cargo_lock,
  }
  in

  let cbindgen = {
    name = "cbindgen-%{matching_version inputs.source.version inputs.crates.version}",
    tag = "Cargo",
    config = {},
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    inputs = {
      source = pkgs.cbindgen_src,
      crates = pkgs.cbindgen_crates,
    },
  }
  in

  {
    include [
      cbindgen_src,
      cbindgen_crates,
      cbindgen,
    ],
  }
