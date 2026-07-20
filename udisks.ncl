# udisks -- we build only the client library libudisks2 (udisks2.pc), a hard
# dependency of gnome-control-center's System panel. Autotools build.
#
# The daemon is disabled (--disable-daemon), which gates away the entire storage
# backend stack (libblockdev, libatasmart, libmount, cryptsetup, ...) -- pointless
# in a diskless QEMU guest, the same call we made for ModemManager's modem
# backends. The client library and its GObject-introspection typelib are enough
# for control-center to build and run.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let udisks_src = fun version =>
    fun hash =>
      {
        name = "udisks-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/storaged-project/udisks/releases/download/udisks-%{version}/udisks-%{version}.tar.bz2",
        },
      }
  in

  let udisks = {
    version | default = "2.11.1",
    source_object_hash
      | default
      = "e88c52bae02fa13414604bbef42c6bb91c2e24177ee0057ed55c6bd7451bcb6d",
    name = "udisks-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgudev,
        pkgs.polkit,
        pkgs.python,
        pkgs.gobject_introspection,
        # g-ir-scanner imports distutils (gone in 3.13); setuptools provides it.
        pkgs.python_setuptools,
        pkgs.libxslt,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libgudev,
        pkgs.polkit,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--sbindir=/usr/bin",
        "--disable-static",
        "--disable-daemon",
        "--disable-man",
        "--enable-introspection",
      ],
    },
    inputs = {
      source = udisks_src version source_object_hash,
    },
  }
  in

  { include [ udisks ] }
