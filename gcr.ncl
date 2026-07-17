# gcr -- GNOME crypto UI/services library (certificates, keys, PKCS#11 access).
# gnome-shell links the base gcr-4 library. Meson build. We build the base
# library only: the GTK4 UI/utilities, the libsecret-backed ssh-agent, systemd
# socket activation, vala bindings and gi-docgen docs are all off -- gnome-shell
# needs libgcr-4, not those. Crypto backend is libgcrypt (the default); trust
# and PKCS#11 come from p11-kit-1.
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = fun v =>
  let p = std.string.split "." v in
  "%{std.array.at 0 p}.%{std.array.at 1 p}"
in

fun pkgs =>
  let gcr_src = fun version =>
    fun hash =>
      {
        name = "gcr-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gcr/%{series version}/gcr-%{version}.tar.xz",
        },
      }
  in

  let gcr = {
    version | default = "4.4.0.1",
    source_object_hash
      | default
      = "0c3c341e49f9f4f2532a4884509804190a0c2663e6120360bb298c5d174a8098",
    name = "gcr-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgcrypt,
        pkgs.p11_kit,
        pkgs.libtasn1,
        pkgs.gobject_introspection,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libgcrypt,
        pkgs.p11_kit,
        pkgs.libtasn1,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        # No gnupg packaged; pin the path so configure skips the gpg lookup.
        # The GnuPG collection is simply inert until a gpg binary exists here.
        "-Dgpg_path=/usr/bin/gpg2",
        "-Dgtk4=false",
        "-Dssh_agent=false",
        "-Dsystemd=disabled",
        "-Dvapi=false",
        "-Dgtk_doc=false",
      ],
    },
    inputs = {
      source = gcr_src version source_object_hash,
    },
  }
  in

  {
    include [
      gcr,
    ],
  }
