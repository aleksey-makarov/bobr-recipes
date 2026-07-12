# cbindgen -- generates C/C++ headers from Rust. A BUILD tool only (mozjs/
# SpiderMonkey runs it to produce headers for its Rust bits); it never ships in
# a runtime rootfs. A plain cargo binary, so it uses the `Cargo` synthetic
# builder: the builder assembles the build rootfs (base_filesystem + toolchain +
# rust_bin), vendors the crates offline from Cargo.lock, and `cargo install`s the
# binary. Because Cargo.lock pins exact versions, `version`, `source_object_hash`
# and `cargo_lock` are coupled overridable fields -- to move versions an overlay
# must override all three together.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "cbindgen-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://static.crates.io/crates/cbindgen/cbindgen-%{version}.crate",
        },
      }
  in

  let cbindgen = {
    version | default = "0.29.4",
    source_object_hash
      | default
      = "2ecb53484c9c167ba674026b656d8a27d7657a58e6066aa902bfb1a4aa00ae20",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "cbindgen-%{version}",
    tag = "Cargo",
    config = {},
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      cbindgen,
    ],
  }
