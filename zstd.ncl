fun pkgs =>
  let zstd_src = fun version => fun hash => {
    name = "zstd-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/facebook/zstd/releases/download/v%{version}/zstd-%{version}.tar.gz",
    },
  }
  in

  let zstd = {
    version | default = "1.5.7",
    source_object_hash | default = "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3",
    name = "zstd-%{version}",
    tag = "Makefile",
    deps = {
      # zstd's Makefile links zlib into the CLI when zlib.h is present (as in the
      # old system_rootfs_2 environment); declare it so the deps-derived build
      # rootfs still has it and the binary is unchanged. lzma comes from xz,
      # which is already in the native toolchain.
      build = [
        pkgs.zlib,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
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
      source = zstd_src version source_object_hash,
    },
  }
  in

  {
    include [
      zstd,
    ],
  }
