let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dbus_src = fun version => fun hash => {
    name = "dbus-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://dbus.freedesktop.org/releases/dbus/dbus-%{version}.tar.xz",
    },
  }
  in

  let dbus = {
    version | default = "1.16.2",
    source_object_hash | default = "0ba2a1a4b16afe7bceb2c07e9ce99a8c2c3508e5dec290dbb643384bd6beb7e2",
    name = "dbus-%{version}",
    tag = "MesonInstall",
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
                "/usr/lib/systemd/system/multi-user.target.wants" \
                "/usr/lib/systemd/system/sockets.target.wants" \
                "/usr/lib/sysusers.d" \
                "/usr/lib/tmpfiles.d"

            sed \
                -e 's#@EXPANDED_BINDIR@#/usr/bin#g' \
                -e 's#@DBUS_USER@#messagebus#g' \
                -e '/@AMBIENT_CAPS@/d' \
                "$dbus_src_root"/bus/dbus.service.in \
                > "/usr/lib/systemd/system/dbus.service"

            sed \
                -e 's#@DBUS_SYSTEM_SOCKET@#/run/dbus/system_bus_socket#g' \
                "$dbus_src_root"/bus/dbus.socket.in \
                > "/usr/lib/systemd/system/dbus.socket"

            sed \
                -e 's#@DBUS_USER@#messagebus#g' \
                "$dbus_src_root"/bus/sysusers.d/dbus.conf.in \
                > "/usr/lib/sysusers.d/dbus.conf"

            sed \
                -e 's#@EXPANDED_LOCALSTATEDIR@#/var#g' \
                "$dbus_src_root"/bus/tmpfiles.d/dbus.conf.in \
                > "/usr/lib/tmpfiles.d/dbus.conf"

            ln -sfv ../dbus.service \
                "/usr/lib/systemd/system/multi-user.target.wants/dbus.service"
            ln -sfv ../dbus.socket \
                "/usr/lib/systemd/system/sockets.target.wants/dbus.socket"

            # Per-user session bus for the systemd --user session (the graphical
            # session's D-Bus). The upstream user templates carry no [Install],
            # so enable the socket by hand in the user sockets.target.wants. This
            # gives DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus.
            install -vdm755 \
                "/usr/lib/systemd/user" \
                "/usr/lib/systemd/user/sockets.target.wants"

            sed \
                -e 's#@SYSTEMCTL@#/usr/bin/systemctl#g' \
                "$dbus_src_root"/bus/systemd-user/dbus.socket.in \
                > "/usr/lib/systemd/user/dbus.socket"

            sed \
                -e 's#@EXPANDED_BINDIR@#/usr/bin#g' \
                "$dbus_src_root"/bus/systemd-user/dbus.service.in \
                > "/usr/lib/systemd/user/dbus.service"

            ln -sfv ../dbus.socket \
                "/usr/lib/systemd/user/sockets.target.wants/dbus.socket"

            install -vdm755 "/var/lib/dbus"
            ln -sfv /etc/machine-id "/var/lib/dbus/machine-id"
          "%,
        ],
      },
    },
    inputs = {
      source = dbus_src version source_object_hash,
    },
  }
  in

  {
    include [
      dbus,
    ],
  }
