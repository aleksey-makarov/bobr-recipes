let recipe = import "../recipe-lib.ncl" in
# gcr -- GNOME crypto UI/services library (certificates, keys, PKCS#11 access).
# gnome-shell links the base gcr-4 library. Meson build. We build the base
# library only: the GTK4 UI/utilities, the libsecret-backed ssh-agent, systemd
# socket activation, vala bindings and gi-docgen docs are all off -- gnome-shell
# needs libgcr-4, not those. Crypto backend is libgcrypt (the default); trust
# and PKCS#11 come from p11-kit-1.
# Configure version and hash through `pkgs.gcr_src`.
let series = recipe.version_prefix 2 in

fun pkgs =>
  let gcr_src = {
    version | default = "4.4.0.1",
    name = "gcr-src-%{version}",
    tag = "Source",
    object_hash | default = "0c3c341e49f9f4f2532a4884509804190a0c2663e6120360bb298c5d174a8098",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gcr/%{series version}/gcr-%{version}.tar.xz",
    },
  }
  in

  let gcr = {
    name = "gcr-%{inputs.source.version}",
    tag = "Meson",
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
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.libgcrypt,
        pkgs.p11_kit,
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
      source = pkgs.gcr_src,
    },
  }
  in

  {
    include [
      gcr_src,
      gcr,
    ],
  }
