let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dbus_src = {
    name = "dbus-src-1.16.2",
    tag = "Source",
    object_hash = "08aec5f9691e5835c19df328d7962b2fc98b770addbf816b2a6804190f2b6818",
    origin = {
      tag = "Http",
      url = "https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz",
    },
  }
  in

  let dbus = {
    name = "dbus-1.16.2",
    tag = "Meson",
    deps = {
      build = [
        pkgs.expat,
        pkgs.libcap,
        pkgs.systemd,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.expat,
        pkgs.systemd_libs,
      ],
    },
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
            dbus_src_root="@{build}/source"

            install -vdm755 \
                "@{out}/usr/lib/systemd/system/multi-user.target.wants" \
                "@{out}/usr/lib/systemd/system/sockets.target.wants" \
                "@{out}/usr/lib/sysusers.d" \
                "@{out}/usr/lib/tmpfiles.d"

            sed \
                -e 's#@EXPANDED_BINDIR@#/usr/bin#g' \
                -e 's#@DBUS_USER@#messagebus#g' \
                -e '/@AMBIENT_CAPS@/d' \
                "$dbus_src_root"/bus/dbus.service.in \
                > "@{out}/usr/lib/systemd/system/dbus.service"

            sed \
                -e 's#@DBUS_SYSTEM_SOCKET@#/run/dbus/system_bus_socket#g' \
                "$dbus_src_root"/bus/dbus.socket.in \
                > "@{out}/usr/lib/systemd/system/dbus.socket"

            sed \
                -e 's#@DBUS_USER@#messagebus#g' \
                "$dbus_src_root"/bus/sysusers.d/dbus.conf.in \
                > "@{out}/usr/lib/sysusers.d/dbus.conf"

            sed \
                -e 's#@EXPANDED_LOCALSTATEDIR@#/var#g' \
                "$dbus_src_root"/bus/tmpfiles.d/dbus.conf.in \
                > "@{out}/usr/lib/tmpfiles.d/dbus.conf"

            ln -sfv ../dbus.service \
                "@{out}/usr/lib/systemd/system/multi-user.target.wants/dbus.service"
            ln -sfv ../dbus.socket \
                "@{out}/usr/lib/systemd/system/sockets.target.wants/dbus.socket"

            # Per-user session bus for the systemd --user session (the graphical
            # session's D-Bus). The upstream user templates carry no [Install],
            # so enable the socket by hand in the user sockets.target.wants. This
            # gives DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus.
            install -vdm755 \
                "@{out}/usr/lib/systemd/user" \
                "@{out}/usr/lib/systemd/user/sockets.target.wants"

            sed \
                -e 's#@SYSTEMCTL@#/usr/bin/systemctl#g' \
                "$dbus_src_root"/bus/systemd-user/dbus.socket.in \
                > "@{out}/usr/lib/systemd/user/dbus.socket"

            sed \
                -e 's#@EXPANDED_BINDIR@#/usr/bin#g' \
                "$dbus_src_root"/bus/systemd-user/dbus.service.in \
                > "@{out}/usr/lib/systemd/user/dbus.service"

            ln -sfv ../dbus.socket \
                "@{out}/usr/lib/systemd/user/sockets.target.wants/dbus.socket"

            install -vdm755 "@{out}/var/lib/dbus"
            ln -sfv /etc/machine-id "@{out}/var/lib/dbus/machine-id"
          "%,
        ],
      },
    },
    inputs = {
      source = dbus_src,
    },
  }
  in

  {
    include [
      dbus,
    ],
  }
