fun pkgs =>
  let rsync_src = fun version => fun hash => {
    name = "rsync-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://download.samba.org/pub/rsync/src/rsync-%{version}.tar.gz",
    },
  }
  in

  let rsync = {
    version | default = "3.4.2",
    source_object_hash | default = "ff10aa2c151cd4b2dbbe6135126dbc854046113d2dfb49572a348233267eb315",
    name = "rsync-%{version}",
    tag = "Autotools",
    deps = {
      # --without-included-zlib links the system zlib, so its headers must be in
      # the build rootfs (system_rootfs_2 provided them; the deps-derived rootfs
      # does not by default).
      build = [
        pkgs.zlib,
      ],
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
      source = rsync_src version source_object_hash,
    },
  }
  in

  {
    include [
      rsync,
    ],
  }
