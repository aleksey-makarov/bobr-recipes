let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let zstd_src = {
    version | default = "1.5.7",
    name = "zstd-src-%{version}",
    tag = "Source",
    object_hash | default = "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3",
    origin = {
      tag = "Http",
      url = "https://github.com/facebook/zstd/releases/download/v%{version}/zstd-%{version}.tar.gz",
    },
  }
  in

  let zstd = {
    name = "zstd-%{inputs.source.version}",
    tag = "Makefile",
    deps = {
      # zstd's Makefile links zlib into the CLI when zlib.h is present (as in the
      # old system_rootfs_2 environment); declare it so the deps-derived build
      # rootfs still has it and the binary is unchanged. The CLI likewise
      # detects liblzma from xz, so keep both optional features explicit.
      build = [
        pkgs.zlib,
        pkgs.xz,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.zlib,
        pkgs.xz_libs,
      ],
    },
    config = {
      make_args = [
        "prefix=/usr",
      ],
      post_install = {
        name = "remove_static_library",
        run_as = "root",
        argv = [
          "rm",
          "-fv",
          "/usr/lib/libzstd.a",
        ],
      },
    },
    inputs = {
      source = pkgs.zstd_src,
    },
  }
  in

  # Static-only companion for build tools that link LLVM component archives.
  # Keep it separate from the ordinary zstd package, whose public contract
  # intentionally removes libzstd.a.
  let zstd_static = {
    name = "zstd-static-%{inputs.source.version}",
    tag = "SandboxInstallDeps",
    deps = {
      build = recipe.native_build_deps pkgs,
      runtime = [],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "build_static",
          run_as = "build-user",
          cwd = "@{build}/source",
          argv = [
            "/usr/bin/make",
            "-C",
            "lib",
            "libzstd.a",
          ],
        },
        {
          name = "install_static",
          run_as = "root",
          cwd = "@{build}/source",
          argv = [
            "/usr/bin/install",
            "-Dm644",
            "lib/libzstd.a",
            "/usr/lib/libzstd.a",
          ],
        },
      ],
    },
    inputs = {
      source = pkgs.zstd_src,
    },
  }
  in

  {
    include [
      zstd_src,
      zstd,
      zstd_static,
    ],
  }
