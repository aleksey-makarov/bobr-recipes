let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_db_src = {
    name = "man-db-src-2.13.1",
    tag = "Fetch",
    config = {
      url = "https://download.savannah.gnu.org/releases/man-db/man-db-2.13.1.tar.xz",
      hash = "md5:b6335533cbeac3b24cd7be31fdee8c83",
    },
    inputs = {},
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
