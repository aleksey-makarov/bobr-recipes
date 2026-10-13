let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let elfutils_src = {
    version | default = "0.193",
    name = "elfutils-src-%{version}",
    tag = "Source",
    object_hash | default = "7857f44b624f4d8d421df851aaae7b1402cfe6bcdd2d8049f15fc07d3dde7635",
    origin = {
      tag = "Http",
      url = "https://sourceware.org/ftp/elfutils/%{version}/elfutils-%{version}.tar.bz2",
    },
  }
  in

  let elfutils = {
    name = "elfutils-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--disable-debuginfod",
        "--disable-libdebuginfod",
        "--libdir=/usr/lib",
        "--with-zlib",
        "--without-bzlib",
        "--without-lzma",
        "--without-zstd",
      ],
    },
    inputs = {
      # bootstrap toolchain (replaces the system-rootfs-1 base) plus elfutils's
      # own extra build deps: bzip2/pkgconf (gen1, this is a gen1-stage build) and
      # zlib, which --with-zlib links.
      _rootfs =
        recipe.bootstrap_toolchain_rootfs
          pkgs
          "elfutils-build-rootfs"
          [
            pkgs.bzip2_gen1,
            pkgs.pkgconf_gen1,
            pkgs.zlib,
          ],
      source = pkgs.elfutils_src,
    },
  }
  in

  {
    include [
      elfutils_src,
      elfutils,
    ],
  }
