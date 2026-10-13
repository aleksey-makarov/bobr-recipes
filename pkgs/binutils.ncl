let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let binutils_src = {
    version | default = "2.45",
    name = "binutils-src-%{version}",
    tag = "Source",
    object_hash | default = "c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2",
    origin = {
      tag = "Http",
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-%{version}.tar.xz",
      ],
    },
  }
  in

  let binutils_gen1 = {
    name = "binutils-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-nls",
        "--without-zstd",
        "--enable-gprofng=no",
        "--disable-werror",
        "--enable-new-dtags",
        "--enable-default-hash-style=gnu",
        "--enable-deterministic-archives",
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.binutils_src,
    },
  }
  in

  let binutils = {
    name = "binutils-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--enable-shared",
        "--enable-64-bit-bfd",
        "--enable-new-dtags",
        "--enable-default-hash-style=gnu",
        "--enable-deterministic-archives",
        "--disable-nls",
        "--disable-werror",
        "--disable-gprofng",
        "--without-zstd",
      ],
    },
    inputs = {
      _rootfs = recipe.gen1_toolchain_rootfs pkgs "binutils-build-rootfs" [],
      source = pkgs.binutils_src,
    },
  }
  in

  {
    include [
      binutils_src,
      binutils_gen1,
      binutils,
    ],
  }
