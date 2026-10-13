# udisks -- we build only the client library libudisks2 (udisks2.pc), a hard
# dependency of gnome-control-center's System panel. Autotools build.
#
# The daemon is disabled (--disable-daemon), which gates away the entire storage
# backend stack (libblockdev, libatasmart, libmount, cryptsetup, ...) -- pointless
# in a diskless QEMU guest, the same call we made for ModemManager's modem
# backends. The client library and its GObject-introspection typelib are enough
# for control-center to build and run.
# Configure version and hash through `pkgs.udisks_src`.
fun pkgs =>
  let udisks_src = {
    version | default = "2.11.1",
    name = "udisks-src-%{version}",
    tag = "Source",
    object_hash | default = "e88c52bae02fa13414604bbef42c6bb91c2e24177ee0057ed55c6bd7451bcb6d",
    origin = {
      tag = "Http",
      url = "https://github.com/storaged-project/udisks/releases/download/udisks-%{version}/udisks-%{version}.tar.bz2",
    },
  }
  in

  let udisks = {
    name = "udisks-%{inputs.source.version}",
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
        pkgs.c_runtime,
        pkgs.glib,
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
      source = pkgs.udisks_src,
    },
  }
  in

  {
    include [
      udisks_src,
      udisks
    ]
  }
