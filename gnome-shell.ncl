# gnome-shell -- the GNOME desktop shell: the mutter-based compositor session UI
# that gjs runs. Meson build. Links libmutter (compositor), libgjs (JS engine),
# gtk4, gcr-4, gnome-desktop-4, polkit-agent-1, evolution-data-server
# (libecal/libedataserver, for the clock/calendar) and at-spi2-core. The
# NetworkManager, camera (pipewire) and portal-helper features are off, the
# GTK4/libadwaita extensions app and the man pages/tests too -- we want the shell
# session, not the full optional surface. systemd integration is on.
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = fun v =>
  let p = std.string.split "." v in
  std.array.at 0 p
in

fun pkgs =>
  let gnome_shell_src = fun version =>
    fun hash =>
      {
        name = "gnome-shell-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-shell/%{series version}/gnome-shell-%{version}.tar.xz",
        },
      }
  in

  let gnome_shell = {
    version | default = "50.3",
    source_object_hash
      | default
      = "450458c44a26d25a9b84288e12b9005d4c5c44648cfc6b790be19a05de7f1735",
    name = "gnome-shell-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.mutter,
        pkgs.gjs,
        pkgs.gtk4,
        pkgs.gcr,
        pkgs.gnome_desktop,
        pkgs.polkit,
        pkgs.evolution_data_server,
        pkgs.at_spi2_core,
        pkgs.pango,
        pkgs.gdk_pixbuf,
        pkgs.json_glib,
        pkgs.libxml2,
        pkgs.gsettings_desktop_schemas,
        pkgs.pulseaudio,
        pkgs.systemd_dev,
        pkgs.gobject_introspection,
        pkgs.gettext,
        pkgs.python,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.mutter,
        pkgs.gjs,
        pkgs.gtk4,
        pkgs.gcr,
        pkgs.gnome_desktop,
        pkgs.polkit,
        pkgs.evolution_data_server,
        pkgs.at_spi2_core,
        pkgs.pango,
        pkgs.gdk_pixbuf,
        pkgs.json_glib,
        pkgs.libxml2,
        pkgs.gsettings_desktop_schemas,
        pkgs.pulseaudio,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dcamera_monitor=false",
        "-Dnetworkmanager=false",
        "-Dportal_helper=false",
        "-Dextensions_app=false",
        "-Dextensions_tool=false",
        "-Dman=false",
        "-Dtests=false",
        "-Dgtk_doc=false",
        "-Dsystemd=true",
      ],
    },
    inputs = {
      source = gnome_shell_src version source_object_hash,
      # Drop the vestigial X11 includes from shell-app-usage.c (no X11 symbols
      # are used); our mutter is Wayland-only, so the X11 headers are not wired
      # into the build. Applied by the synthetic builder (input name matches
      # ^patch, so it lands in BOBR_PATCH_INPUTS).
      patch_no_x11 = {
        name = "gnome-shell-no-x11-patch",
        tag = "Source",
        object_hash = import "gnome-shell-no-x11.patch.fsobj-hash" as 'Text,
        origin = {
          tag = "RecipePath",
          path = "gnome-shell-no-x11.patch",
        },
      },
    },
  }
  in

  {
    include [
      gnome_shell,
    ],
  }
