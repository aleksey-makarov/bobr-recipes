let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_db_src =
    {
      name = "man-db-src-2.13.1",
      tag = "Fetch",
      config = {
      url = "https://download.savannah.gnu.org/releases/man-db/man-db-2.13.1.tar.xz",
      hash = "md5:b6335533cbeac3b24cd7be31fdee8c83",
      },
      inputs = {},
    }
  in

  let man_db_build_image =
    recipe.image "man-db-build-image" {} pkgs.system_image [
      pkgs.gdbm,
      pkgs.groff,
      pkgs.libpipeline,
    ]
  in

  let man_db =
    recipe.binary "man-db-2.13.1" {
      script_config = {
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
    } man_db_build_image pkgs.buildscript_autotools [man_db_src]
  in

  {
    include [
      man_db_src,
      man_db,
    ],
  }
