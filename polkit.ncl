# polkit -- the system authorization framework. gnome-shell links its
# polkit-agent-1 library (the in-session authentication agent) and talks to
# polkitd. Meson build. Rule evaluation uses the duktape JS engine (polkit
# dropped mozjs). Session tracking via logind (libsystemd), authentication via
# PAM. Docs/tests/examples/man are off. Upstream ships no release tarball, so we
# take the static GitHub archive; the meson project version is hardcoded, so the
# archive (no git metadata) builds fine.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let polkit_src = fun version =>
    fun hash =>
      {
        name = "polkit-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/polkit-org/polkit/archive/refs/tags/%{version}.tar.gz",
        },
      }
  in

  let polkit = {
    version | default = "126",
    source_object_hash
      | default
      = "2814a7281989f6baa9e57bd33bbc5e148827e2721ccef22aaf28ab2b376068e8",
    name = "polkit-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.expat,
        pkgs.dbus,
        pkgs.duktape,
        pkgs.linux_pam,
        pkgs.systemd_dev,
        pkgs.gobject_introspection,
        pkgs.gettext,
        pkgs.perl,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.expat,
        pkgs.dbus,
        pkgs.duktape,
        pkgs.linux_pam,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "--sbindir=/usr/bin",
        "-Dsession_tracking=logind",
        "-Dauthfw=pam",
        "-Dexamples=false",
        "-Dtests=false",
        "-Dman=false",
        "-Dgtk_doc=false",
      ],
    },
    inputs = {
      source = polkit_src version source_object_hash,
    },
  }
  in

  {
    include [
      polkit,
    ],
  }
