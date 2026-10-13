let recipe = import "../recipe-lib.ncl" in
# gnome-control-center -- the GNOME Settings application. The final leaf of the
# desktop: it pulls together nearly the whole session stack. Meson build.
#
# On x86_64 Linux the Network/WWan/Bluetooth/Wacom panels are not optional, so
# the full set of hard dependencies is present: libnm + libnma-gtk4 + mm-glib
# (ModemManager), gnome-bluetooth-ui-3.0, libwacom, plus goa, cups, pwquality,
# colord, gcr-4, polkit, gsound, accountsservice, upower, pulseaudio, gnome-
# desktop-4/gnome-bg-4, gnome-settings-daemon and libadwaita. IBus support is on
# (the Keyboard panel). Documentation, tests, Snap and malcontent are off.
# Configure version and hash through `pkgs.gnome_control_center_src`.
fun pkgs =>
  let series = recipe.version_prefix 1 in

  let gnome_control_center_src = {
    version | default = "50.3",
    name = "gnome-control-center-src-%{version}",
    tag = "Source",
    object_hash | default = "06eebb0fd3056c4d8d78bbd3754c96108f381d70b760da423c5024946944287c",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gnome-control-center/%{series version}/gnome-control-center-%{version}.tar.xz",
    },
  }
  in

  let gnome_control_center = {
    name = "gnome-control-center-%{inputs.source.version}",
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
        pkgs.gnome_online_accounts,
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
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.accountsservice,
        pkgs.colord,
        pkgs.colord_gtk,
        pkgs.gnome_desktop,
        pkgs.gnome_settings_daemon,
        pkgs.gnome_online_accounts,
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
      source = pkgs.gnome_control_center_src,
    },
  }
  in

  {
    include [
      gnome_control_center_src,
      gnome_control_center,
    ],
  }
