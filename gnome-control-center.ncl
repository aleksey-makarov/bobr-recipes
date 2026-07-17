# gnome-control-center -- the GNOME Settings application. The final leaf of the
# desktop: it pulls together nearly the whole session stack. Meson build.
#
# On x86_64 Linux the Network/WWan/Bluetooth/Wacom panels are not optional, so
# the full set of hard dependencies is present: libnm + libnma-gtk4 + mm-glib
# (ModemManager), gnome-bluetooth-ui-3.0, libwacom, plus goa, cups, pwquality,
# colord, gcr-4, polkit, gsound, accountsservice, upower, pulseaudio, gnome-
# desktop-4/gnome-bg-4, gnome-settings-daemon and libadwaita. IBus support is on
# (the Keyboard panel). Documentation, tests, Snap and malcontent are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let series = fun v => std.array.at 0 (std.string.split "." v) in

  let cc_src = fun version =>
    fun hash =>
      {
        name = "gnome-control-center-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-control-center/%{series version}/gnome-control-center-%{version}.tar.xz",
        },
      }
  in

  let gnome_control_center = {
    version | default = "50.3",
    source_object_hash
      | default
      = "06eebb0fd3056c4d8d78bbd3754c96108f381d70b760da423c5024946944287c",
    name = "gnome-control-center-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.accountsservice,
        pkgs.colord,
        pkgs.colord_gtk,
        pkgs.gdk_pixbuf,
        pkgs.gnome_desktop,
        pkgs.gnome_settings_daemon,
        pkgs.goa,
        pkgs.gsettings_desktop_schemas,
        pkgs.libxml2,
        pkgs.pulseaudio,
        pkgs.upower,
        pkgs.libgudev,
        pkgs.systemd_dev,
        pkgs.libgtop,
        pkgs.libepoxy,
        pkgs.gcr,
        pkgs.libpwquality,
        pkgs.polkit,
        pkgs.krb5,
        # com_err.h/com_err.pc for krb5.h -- krb5 ships com_err bundled but we
        # strip its duplicate from the tree, so the build takes com_err from
        # e2fsprogs (the same provider as the runtime base rootfs).
        pkgs.e2fsprogs,
        pkgs.udisks,
        pkgs.cups,
        pkgs.samba,
        pkgs.ibus,
        pkgs.json_glib,
        pkgs.modemmanager,
        pkgs.networkmanager,
        pkgs.libnma,
        pkgs.gnome_bluetooth,
        pkgs.libwacom,
        pkgs.gsound,
        pkgs.tecla,
        pkgs.blueprint_compiler,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.accountsservice,
        pkgs.colord,
        pkgs.colord_gtk,
        pkgs.gnome_desktop,
        pkgs.gnome_settings_daemon,
        pkgs.goa,
        pkgs.gsettings_desktop_schemas,
        pkgs.libxml2,
        pkgs.pulseaudio,
        pkgs.upower,
        pkgs.libgudev,
        pkgs.libgtop,
        pkgs.libepoxy,
        pkgs.gcr,
        pkgs.libpwquality,
        pkgs.polkit,
        pkgs.krb5,
        pkgs.udisks,
        pkgs.cups,
        pkgs.samba,
        pkgs.ibus,
        pkgs.json_glib,
        pkgs.modemmanager,
        pkgs.networkmanager,
        pkgs.libnma,
        pkgs.gnome_bluetooth,
        pkgs.libwacom,
        pkgs.gsound,
        pkgs.tecla,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddocumentation=false",
        "-Dtests=false",
        "-Dsnap=false",
        "-Dmalcontent=false",
      ],
    },
    inputs = {
      source = cc_src version source_object_hash,
    },
  }
  in

  {
    include [
      gnome_control_center,
    ],
  }
