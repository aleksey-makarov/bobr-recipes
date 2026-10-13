fun pkgs =>
  let rsync_src = {
    version | default = "3.4.2",
    name = "rsync-src-%{version}",
    tag = "Source",
    object_hash | default = "ff10aa2c151cd4b2dbbe6135126dbc854046113d2dfb49572a348233267eb315",
    origin = {
      tag = "Http",
      url = "https://download.samba.org/pub/rsync/src/rsync-%{version}.tar.gz",
    },
  }
  in

  let rsync = {
    name = "rsync-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      # --without-included-zlib links the system zlib, so its headers must be in
      # the build rootfs (system_rootfs_2 provided them; the deps-derived rootfs
      # does not by default).
      build = [
        pkgs.zlib,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.rsync_src,
    },
  }
  in

  {
    include [
      rsync_src,
      rsync,
    ],
  }
