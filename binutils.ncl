let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkg_name = "binutils" in
  let pkg_version = "2.45" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let gen1_name = "%{pkg_name}-gen1-%{pkg_version}" in

  let binutils_src = {
    name = source_name,
    tag = "Source",
    object_hash = "c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2",
    origin = {
      tag = "Http",
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
      ],
    },
  }
  in

  let binutils_gen1 = {
    name = gen1_name,
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
      source = binutils_src,
    },
  }
  in

  let binutils = {
    name = "binutils-2.45",
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
      _rootfs = pkgs.system_rootfs_0,
      source = binutils_src,
    },
  }
  in

  {
    include [
      binutils_gen1,
      binutils,
    ],
  }
