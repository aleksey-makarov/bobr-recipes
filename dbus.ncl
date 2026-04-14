let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dbus_src =
    recipe.fetch "dbus-src-1.16.2" {
      url = "https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz",
      hash = "md5:97832e6f0a260936d28536e5349c22e5",
    }
  in

  let dbus =
    recipe.binary "dbus-1.16.2" {
      script_config = {
        setup_args = [
          "--buildtype=release",
          "--wrap-mode=nofallback",
        ],
        post_install = m%"
          install -vdm755 /out/${out}/var/lib/dbus
          ln -sfv /etc/machine-id /out/${out}/var/lib/dbus/machine-id
        "%,
      },
    } pkgs.system_image pkgs.buildscript_meson [dbus_src]
  in

  {
    include [
      dbus_src,
      dbus,
    ],
  }
