let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkg_name = "binutils" in
  let pkg_version = "2.45" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let gen1_name = "%{pkg_name}-gen1-%{pkg_version}" in

  let binutils_src = {
    name = source_name,
    tag = "Fetch",
    config = {
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
      ],
      hash = "md5:dee5b4267e0305a99a3c9d6131f45759",
    },
    inputs = {},
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

  let binutils =
    recipe.binary
      "binutils-2.45"
      {
        script_config = {
          build_dir = "build",
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
      }
      pkgs.system_image_0
      pkgs.buildscript_autotools
      [binutils_src]
  in

  {
    include [
      binutils_src,
      binutils_gen1,
      binutils,
    ],
  }
