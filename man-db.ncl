let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_db_src = fun version => fun hash => {
    name = "man-db-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/man-db/man-db-%{version}.tar.xz",
    },
  }
  in

  let man_db = {
    version | default = "2.13.1",
    source_object_hash | default = "8afebb6f7eb6bb8542929458841f5c7e6f240e30c86358c1fbcefbea076c87d9",
    name = "man-db-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.gdbm,
        pkgs.groff,
        pkgs.libpipeline,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gdbm,
        pkgs.groff,
        pkgs.libpipeline,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/man-db-%{version}",
        "--sysconfdir=/etc",
        "--sbindir=/usr/bin",
        "--disable-setuid",
        "--enable-cache-owner=bin",
        "--with-systemdsystemunitdir=/usr/lib/systemd/system",
        "--with-systemdtmpfilesdir=/usr/lib/tmpfiles.d",
        "--with-browser=/usr/bin/lynx",
        "--with-vgrind=/usr/bin/vgrind",
        "--with-grap=/usr/bin/grap",
      ],
    },
    inputs = {
      source = man_db_src version source_object_hash,
    },
  }
  in

  {
    include [
      man_db,
    ],
  }
