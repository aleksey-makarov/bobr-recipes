fun pkgs =>
  let rsync_src = {
    name = "rsync-src-3.4.2",
    tag = "Source",
    object_hash = "932bbcf4f188a42176ed09b34537f5879ad79a8756e6e3b13301a839c5fbae9c",
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
