let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let pkg_name = "binutils" in
  let pkg_version = "2.45" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let gen1_name = "%{pkg_name}-gen1-%{pkg_version}" in

  let binutils_src_2_45 =
    recipe.fetch source_name {
      url = [
        "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
        "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
      ],
      hash = "md5:dee5b4267e0305a99a3c9d6131f45759",
    }
  in

  let binutils_gen1_2_45 =
    recipe.binary gen1_name {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        build_dir = "build",
        configure_args = [
          "--disable-nls",
          "--without-zstd",
          "--enable-gprofng=no",
          "--disable-werror",
          "--enable-new-dtags",
          "--enable-default-hash-style=gnu",
        ],
      },
    } pkgs.host_image pkgs.buildscript_autotools [binutils_src_2_45]
  in

  let binutils_2_45 =
    build.build_bootstrap_autotools {
      name = "binutils-2.45",
      sources = [binutils_src_2_45],
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
  in

  {
    include [
      binutils_src_2_45,
      binutils_gen1_2_45,
      binutils_2_45,
    ],
  }
