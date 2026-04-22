let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dbus_src = {
    name = "dbus-src-1.16.2",
    tag = "Fetch",
    config = {
      url = "https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz",
      hash = "md5:97832e6f0a260936d28536e5349c22e5",
    },
    inputs = {},
  }
  in

  let dbus_build_image = {
    name = "dbus-build-image",
    tag = "Image",
    config = { ref_name | default = "dbus-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.libcap,
        pkgs.systemd,
      ],
  }
  in

  let dbus = {
    name = "dbus-1.16.2",
    tag = "Meson",
    config = {
      setup_args = [
        "--buildtype=release",
        "--wrap-mode=nofallback",
        "-Dsystemd=enabled",
        "-Dsystemd_system_unitdir=/usr/lib/systemd/system",
      ],
      post_install = {
        name = "install_systemd_units",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            dbus_src_root="${source}"

            install -vdm755 \
                "${out}/usr/lib/systemd/system/multi-user.target.wants" \
                "${out}/usr/lib/systemd/system/sockets.target.wants" \
                "${out}/usr/lib/sysusers.d" \
                "${out}/usr/lib/tmpfiles.d"

            sed \
                -e 's#@EXPANDED_BINDIR@#/usr/bin#g' \
                -e 's#@DBUS_USER@#messagebus#g' \
                -e '/@AMBIENT_CAPS@/d' \
                "${dbus_src_root}/bus/dbus.service.in" \
                > "${out}/usr/lib/systemd/system/dbus.service"

            sed \
                -e 's#@DBUS_SYSTEM_SOCKET@#/run/dbus/system_bus_socket#g' \
                "${dbus_src_root}/bus/dbus.socket.in" \
                > "${out}/usr/lib/systemd/system/dbus.socket"

            sed \
                -e 's#@DBUS_USER@#messagebus#g' \
                "${dbus_src_root}/bus/sysusers.d/dbus.conf.in" \
                > "${out}/usr/lib/sysusers.d/dbus.conf"

            sed \
                -e 's#@EXPANDED_LOCALSTATEDIR@#/var#g' \
                "${dbus_src_root}/bus/tmpfiles.d/dbus.conf.in" \
                > "${out}/usr/lib/tmpfiles.d/dbus.conf"

            ln -sfv ../dbus.service \
                "${out}/usr/lib/systemd/system/multi-user.target.wants/dbus.service"
            ln -sfv ../dbus.socket \
                "${out}/usr/lib/systemd/system/sockets.target.wants/dbus.socket"

            install -vdm755 "${out}/var/lib/dbus"
            ln -sfv /etc/machine-id "${out}/var/lib/dbus/machine-id"
          "%,
        ],
      },
    },
    inputs = {
      image = dbus_build_image,
      source = dbus_src,
    },
  }
  in

  {
    include [
      dbus_src,
      dbus,
    ],
  }
