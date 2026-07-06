let recipe = import "recipe-lib.ncl" in
let hashes = {
  "1.8.6" = "e9dba06bef8d9ac66966d9461d36f7aad24e27f1607017e57625abbf958bb37e",
}
in

fun pkgs =>
  let erofs_utils_src = fun version =>
    {
      name = "erofs-utils-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git/snapshot/erofs-utils-%{version}.tar.gz",
      },
    }
  in

  let erofs_utils = {
    version | default = "1.8.6",
    name = "erofs-utils-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        # autogen.sh (the kernel.org snapshot ships no configure script) needs
        # automake and libtool on top of the default autoconf/m4; pkgconf backs
        # the PKG_CHECK_MODULES lookups. lz4, zlib, and util-linux (libuuid) are
        # linked at build time.
        pkgs.automake,
        pkgs.libtool,
        pkgs.pkgconf,
        pkgs.lz4,
        pkgs.zlib,
        pkgs.util_linux,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.lz4,
        pkgs.zlib,
        pkgs.util_linux_libs,
      ],
    },
    config = {
      # The snapshot has only configure.ac; generate configure first. autogen.sh
      # runs aclocal/autoheader/autoconf/libtoolize/automake and does not itself
      # run ./configure, so the normal Autotools configure step follows.
      pre_configure = {
        name = "autogen",
        run_as = "build-user",
        argv = ["/bin/sh", "-ec", "./autogen.sh"],
      },
      # LZ4 compression is required; zlib (deflate) and libuuid are auto-detected
      # from the build environment. The rest is off to keep the closure minimal.
      configure_args = [
        "--enable-lz4",
        "--disable-lzma",
        "--disable-fuse",
        "--without-libdeflate",
        "--without-libzstd",
        "--without-xxhash",
        "--without-selinux",
      ],
    },
    inputs = {
      source = erofs_utils_src version,
    },
  }
  in

  {
    include [
      erofs_utils,
    ],
  }
