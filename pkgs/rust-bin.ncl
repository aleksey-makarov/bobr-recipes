let recipe = import "../recipe-lib.ncl" in

# Prebuilt Rust toolchain (rustc + cargo + host std + rustfmt), used as a BUILD
# tool only (glycin/librsvg/mozjs need Rust, and mozjs runs rustfmt on its
# bindgen output; bootstrapping Rust from source is a huge
# detour). The official dist targets an old glibc, so it runs on our newer glibc
# (forward-compatible); rustc is relocatable (finds its sysroot next to the
# binary), so installing it to /usr works. It never ships in a runtime rootfs --
# only appears in build rootfs closures. `version`/`source_object_hash` are node fields
# (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "rust-bin-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://static.rust-lang.org/dist/rust-%{version}-x86_64-unknown-linux-gnu.tar.xz",
        },
      }
  in

  let rust_bin = {
    version | default = "1.97.0",
    source_object_hash | default = "1cf17e4905b841d4c8e3f76467ac148d55fb3f54bf213c86f0d287a36471d904",
    name = "rust-bin-%{version}",
    tag = "SandboxInstallDeps",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
        pkgs.grep,
        pkgs.sed,
        pkgs.gawk,
      ],
      runtime = [
        pkgs.c_runtime,
        # rustc/cargo link libz.so.1; without it they fail to start in a build
        # rootfs that has no other zlib provider (glycin only got it transitively
        # via glib).
        pkgs.zlib,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              cd "@{build}/source"
              ./install.sh \
                --prefix="/usr" \
                --components=rustc,cargo,rust-std-x86_64-unknown-linux-gnu,rustfmt-preview \
                --disable-ldconfig \
                --without=rust-docs
            "%,
          ],
        },
      ],
      script_config = {},
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  # Target standard library used to build the HostBundle launcher as a static
  # musl executable for the native x86_64 package set. Keep this as a separate
  # build-only layer instead of enlarging rust_bin for every Rust consumer.
  # The target archive must always have exactly the same version as rust_bin.
  let mk_rust_std_native_musl_src = fun version => fun hash => {
    name = "rust-std-x86-64-unknown-linux-musl-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://static.rust-lang.org/dist/rust-std-%{version}-x86_64-unknown-linux-musl.tar.xz",
    },
  }
  in

  let rust_std_native_musl = {
    version | default = rust_bin.version,
    source_object_hash
      | default
      = "9744b43bed4a89db05e83dc8054d3e92e23ddb70a6c08c54ccde9a58d7b28627",
    name = "rust-std-native-musl-%{version}",
    tag = "SandboxStageDeps",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
      ],
      runtime = [],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install_target_std",
          run_as = "root",
          cwd = "@{build}",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              target=x86_64-unknown-linux-musl
              source="@{build}/source/rust-std-$target/lib/rustlib/$target"
              test -d "$source/lib/self-contained"
              install -d /stage/usr/lib/rustlib
              cp -a "$source" /stage/usr/lib/rustlib/
            "%,
          ],
        },
      ],
      script_config = {},
    },
    inputs = {
      source = mk_rust_std_native_musl_src version source_object_hash,
    },
  }
  in

  {
    include [
      rust_bin,
      rust_std_native_musl,
    ],
  }
