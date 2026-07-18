let recipe = import "recipe-lib.ncl" in

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
    tag = "SandboxInstallBuild",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
        pkgs.grep,
        pkgs.sed,
        pkgs.gawk,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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

  {
    include [
      rust_bin,
    ],
  }
