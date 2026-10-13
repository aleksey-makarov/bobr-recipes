fun pkgs =>
  let file_src = {
    version | default = "5.46",
    name = "file-src-%{version}",
    tag = "Source",
    object_hash | default = "c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088",
    origin = {
      tag = "Http",
      url = "https://astron.com/pub/file/file-%{version}.tar.gz",
    },
  }
  in

  let file = {
    name = "file-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      # file's configure auto-links compression libs when their headers are
      # present: bzip2 and xz(lzma) come from the native toolchain, but zlib must
      # be added so libmagic keeps gzip support (system_rootfs_2 provided zlib).
      build = [
        pkgs.zlib,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.zlib,
        pkgs.xz_libs,
        pkgs.bzip2,
      ],
    },
    config = {
      configure_args = [],
    },
    inputs = {
      source = pkgs.file_src,
    },
  }
  in

  {
    include [
      file_src,
      file,
    ],
  }
