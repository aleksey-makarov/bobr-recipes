let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkg_name = "binutils" in
  let pkg_version = "2.45" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let gen1_name = "%{pkg_name}-gen1-%{pkg_version}" in

  let binutils_src = {
    name = source_name,
    tag = "Source",
    object_hash = "f6f8cf20a147394819074094d119cdf9158e5088db8de8f759e56266a5b7910c",
    origin = {
      type = "http",
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let binutils_gen1 = {
    name = gen1_name,
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-zstd",
        "--enable-gprofng=no",
        "--disable-werror",
        "--enable-new-dtags",
        "--enable-default-hash-style=gnu",
      ],
    },
    inputs = {
      image = pkgs.host_image,
      source = binutils_src,
    },
  }
  in

  let binutils = {
    name = "binutils-2.45",
    tag = "Autotools",
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
        "--enable-shared",
        "--enable-64-bit-bfd",
        "--enable-new-dtags",
        "--enable-default-hash-style=gnu",
        "--disable-nls",
        "--disable-werror",
        "--disable-gprofng",
        "--without-zstd",
      ],
    },
    inputs = {
      image = pkgs.system_image_0,
      source = binutils_src,
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
