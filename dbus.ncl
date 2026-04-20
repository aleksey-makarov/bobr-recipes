let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dbus_src =
    {
      name = "dbus-src-1.16.2",
      tag = "Fetch",
      config = {
      url = "https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz",
      hash = "md5:97832e6f0a260936d28536e5349c22e5",
      },
      inputs = {},
    }
  in

  let dbus_build_image =
    recipe.image "dbus-build-image" {} pkgs.system_image [
      pkgs.libcap,
      pkgs.systemd,
    ]
  in

  let dbus =
    recipe.binary "dbus-1.16.2" {
      script_config = {
        setup_args = [
          "--buildtype=release",
          "--wrap-mode=nofallback",
          "-Dsystemd=enabled",
          "-Dsystemd_system_unitdir=/usr/lib/systemd/system",
        ],
        post_install = m%"
          dbus_src_root=/in/sources0

          install -vdm755 \
              ${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/multi-user.target.wants \
              ${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/sockets.target.wants \
              ${MBUILD_INSTALL_DIR}/usr/lib/sysusers.d \
              ${MBUILD_INSTALL_DIR}/usr/lib/tmpfiles.d

          sed \
              -e 's#@EXPANDED_BINDIR@#/usr/bin#g' \
              -e 's#@DBUS_USER@#messagebus#g' \
              -e '/@AMBIENT_CAPS@/d' \
              "${dbus_src_root}/bus/dbus.service.in" \
              > ${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/dbus.service

          sed \
              -e 's#@DBUS_SYSTEM_SOCKET@#/run/dbus/system_bus_socket#g' \
              "${dbus_src_root}/bus/dbus.socket.in" \
              > ${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/dbus.socket

          sed \
              -e 's#@DBUS_USER@#messagebus#g' \
              "${dbus_src_root}/bus/sysusers.d/dbus.conf.in" \
              > ${MBUILD_INSTALL_DIR}/usr/lib/sysusers.d/dbus.conf

          sed \
              -e 's#@EXPANDED_LOCALSTATEDIR@#/var#g' \
              "${dbus_src_root}/bus/tmpfiles.d/dbus.conf.in" \
              > ${MBUILD_INSTALL_DIR}/usr/lib/tmpfiles.d/dbus.conf

          ln -sfv ../dbus.service \
              ${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/multi-user.target.wants/dbus.service
          ln -sfv ../dbus.socket \
              ${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/sockets.target.wants/dbus.socket

          install -vdm755 ${MBUILD_INSTALL_DIR}/var/lib/dbus
          ln -sfv /etc/machine-id ${MBUILD_INSTALL_DIR}/var/lib/dbus/machine-id
        "%,
      },
    } dbus_build_image pkgs.buildscript_meson [dbus_src]
  in

  {
    include [
      dbus_src,
      dbus,
    ],
  }
