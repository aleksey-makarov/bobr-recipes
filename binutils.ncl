let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let binutils_src = fun version => fun hash => {
    name = "binutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "2.45",
    source_object_hash | default = "c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2",
    name = "binutils-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
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
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = binutils_src version source_object_hash,
    },
  }
  in

  let binutils = {
    version | default = "2.45",
    source_object_hash | default = "c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2",
    name = "binutils-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
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
      source = binutils_src version source_object_hash,
    },
  }
  in

  {
    include [
      binutils_gen1,
      binutils,
    ],
  }
