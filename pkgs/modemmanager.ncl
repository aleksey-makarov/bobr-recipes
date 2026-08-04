# ModemManager -- provides mm-glib (libmm-glib) and the ModemManager D-Bus
# service. gnome-control-center's WWan/Network panels hard-require mm-glib
# (meson.build: `dependency('mm-glib', version: '>= 0.7')` on Linux). Upstream
# stopped shipping release tarballs after 1.18 (Arch et al. build from the git
# tag), so the source is the GitLab tag archive.
#
# The modem backends (MBIM, QMI, QRTR) are turned off so we need neither
# libmbim/libqmi/libqrtr; there is no modem hardware in the QEMU guest anyway.
# We just want the client library and its MM-1.0 typelib for control-center.
# polkit, the systemd suspend/resume + journal integration, man pages, bash
# completion, tests and examples are all off. udev/gudev stay on (gudev-1.0 and
# udev.pc come from systemd-dev); libsystemd.pc (needed by dbus-1.pc) too.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let mm_src = fun version =>
    fun hash =>
      {
        name = "ModemManager-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/archive/%{version}/ModemManager-%{version}.tar.gz",
        },
      }
  in

  let modemmanager = {
    version | default = "1.24.2",
    source_object_hash
      | default
      = "fbc75adcc0d7b0565f256e7ff4e8872b0a37c4413ff576665f7470932d9c1b68",
    name = "ModemManager-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgudev,
        pkgs.systemd_dev,
        pkgs.dbus,
        pkgs.libxslt,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libgudev,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        # merged-usr: /usr/sbin is a symlink to bin, so the daemon must install
        # into /usr/bin, not a real /usr/sbin directory.
        "--sbindir=/usr/bin",
        "-Dmbim=false",
        "-Dqmi=false",
        "-Dqrtr=false",
        "-Dpolkit=no",
        "-Dsystemd_suspend_resume=false",
        "-Dsystemd_journal=false",
        "-Dsystemdsystemunitdir=/usr/lib/systemd/system",
        "-Dbash_completion=false",
        "-Dman=false",
        "-Dtests=false",
        "-Dexamples=false",
        "-Dvapi=false",
        "-Dintrospection=true",
      ],
    },
    inputs = {
      source = mm_src version source_object_hash,
    },
  }
  in

  {
    include [
      modemmanager,
    ],
  }
