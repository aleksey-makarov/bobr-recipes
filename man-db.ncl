let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_db_src = {
    name = "man-db-src-2.13.1",
    tag = "Source",
    object_hash = "e435621a29891fe2f93f2eee01e5912b5a35a38a1c321878f4d4c3dd2b598b85",
    origin = {
      type = "http",
      url = "https://download.savannah.gnu.org/releases/man-db/man-db-2.13.1.tar.xz",
    },
    meta = {},
  }
  in

  let man_db_build_image = {
    name = "man-db-build-image",
    tag = "Image",
    config = { ref_name | default = "man-db-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.gdbm,
        pkgs.groff,
        pkgs.libpipeline,
      ],
  }
  in

  let man_db = {
    name = "man-db-2.13.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/man-db-2.13.1",
        "--sysconfdir=/etc",
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
      image = man_db_build_image,
      source = man_db_src,
    },
  }
  in

  {
    include [
      man_db_src,
      man_db,
    ],
  }
