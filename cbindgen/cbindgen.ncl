# cbindgen -- generates C/C++ headers from Rust. A BUILD tool only (mozjs/
# SpiderMonkey runs it to produce headers for its Rust bits); it never ships in
# a runtime rootfs. Pure-Rust cargo binary: built offline against crates vendored
# from its Cargo.lock (via cargo.ncl + the Bundle builder), the same way glycin
# vendors its workspace. Because Cargo.lock pins exact versions, `version`,
# `source_object_hash` and `cargo_lock` are coupled overridable fields -- to move
# versions an overlay must override all three together.
#
# Built with SandboxBuildRootfs in a full toolchain base (system_rootfs_2 has
# gcc, binutils/ld, glibc with crt objects, bash, tar) plus rust_bin merged in;
# a bare SandboxBuild has no toolchain (gcc alone pulls only glibc_libs, no ld).
let cargo = import "../cargo.ncl" in
let recipe = import "../recipe-lib.ncl" in

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

  # Full C/Rust toolchain to build in: the stage-2 system (gcc/binutils/glibc)
  # plus the prebuilt Rust (cargo/rustc). zlib is already in system_rootfs_2, so
  # it is NOT merged again (a duplicate would be a TreeMerge conflict).
  let cbindgen_build_rootfs = {
    name = "cbindgen-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.rust_bin,
      ],
  }
  in

  # Unpack each bundled `.crate` into a cargo `vendor/` tree and point cargo at
  # it offline (mirrors glycin's vendor step). cargo reads $CARGO_HOME/config.toml
  # in the build step.
  let vendor_crates_step = {
    name = "bobr_vendor_crates",
    run_as = "build-user",
    cwd = "@{build}",
    argv = [
      "/bin/sh",
      "-ec",
      m%%"
        vendor="@{build}/vendor"
        mkdir -p "$vendor"
        for crate in "@{crates}"/*; do
          tmp="$(mktemp -d)"
          tar -C "$tmp" -xf "$crate"
          top="$(ls "$tmp")"
          mv "$tmp/$top" "$vendor/$top"
          rmdir "$tmp"
          sha="$(sha256sum "$crate" | cut -d' ' -f1)"
          printf '{"files":{},"package":"%s"}' "$sha" > "$vendor/$top/.cargo-checksum.json"
        done
        mkdir -p "@{build}/.cargo"
        cat > "@{build}/.cargo/config.toml" <<EOF
        [source.crates-io]
        replace-with = "vendored-sources"

        [source.vendored-sources]
        directory = "$vendor"

        [net]
        offline = true
        EOF
      "%%,
    ],
  }
  in

  let cbindgen = {
    version | default = "0.29.4",
    source_object_hash
      | default
      = "2ecb53484c9c167ba674026b656d8a27d7657a58e6066aa902bfb1a4aa00ae20",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "cbindgen-%{version}",
    tag = "SandboxBuildRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        vendor_crates_step,
        {
          name = "cargo_build",
          run_as = "build-user",
          cwd = "@{build}/source",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              export CARGO_HOME="@{build}/.cargo"
              export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc
              export CC=gcc
              cargo build --release --offline --locked
            "%,
          ],
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              install -Dm755 "@{build}/source/target/release/cbindgen" \
                "@{out}/usr/bin/cbindgen"
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = cbindgen_build_rootfs,
      source = mk_src version source_object_hash,
      crates = cargo.vendor_bundle "cbindgen-crates-%{version}" cargo_lock,
    },
  }
  in

  {
    include [
      cbindgen,
    ],
  }
