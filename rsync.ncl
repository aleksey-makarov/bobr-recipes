fun pkgs =>
  let rsync_src = {
    name = "rsync-src-3.4.2",
    tag = "Source",
    object_hash = "ff10aa2c151cd4b2dbbe6135126dbc854046113d2dfb49572a348233267eb315",
    origin = {
      tag = "Http",
      url = "https://download.samba.org/pub/rsync/src/rsync-3.4.2.tar.gz",
    },
  }
  in

  let rsync = {
    name = "rsync-3.4.2",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
      ],
    },
    config = {
      configure_args = [
        "--disable-openssl",
        "--disable-xxhash",
        "--disable-zstd",
        "--disable-lz4",
        "--without-included-zlib",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = rsync_src,
    },
  }
  in

  {
    include [
      rsync,
    ],
  }
