# CUPS (client library + headers) -- gnome-control-center's Printers panel links
# against libcups and requires cups.h/ppd.h (a hard dependency: meson.build
# asserts CUPS >= 1.4). We only need the client library and its pkg-config file,
# so the scheduler-side extras (Avahi mDNS, systemd activation, PAM, the web UI
# languages) are turned off. TLS is provided by OpenSSL.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let cups_src = fun version =>
    fun hash =>
      {
        name = "cups-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/OpenPrinting/cups/releases/download/v%{version}/cups-%{version}-source.tar.gz",
        },
      }
  in

  let cups = {
    version | default = "2.4.19",
    source_object_hash
      | default
      = "820984b12a67f98705785aae2dd1347fe0ac097828001d4583ff64574aed6389",
    name = "cups-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.zlib,
        pkgs.openssl,
        pkgs.libxcrypt,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.zlib,
        pkgs.openssl,
        pkgs.libxcrypt_libs,
      ],
    },
    config = {
      # CUPS ships its Makefiles in-tree (configure only generates Makedefs);
      # it does not support a separate build directory.
      "in-tree" = true,
      configure_args = [
        "--libdir=/usr/lib",
        # merged-usr: /usr/sbin is a symlink to bin, so the daemon binaries must
        # install into /usr/bin, not a real /usr/sbin directory.
        "--sbindir=/usr/bin",
        "--with-tls=openssl",
        "--disable-avahi",
        "--disable-systemd",
        "--disable-pam",
        "--disable-dbus",
        "--disable-libusb",
        "--without-rundir",
      ],
    },
    inputs = {
      source = cups_src version source_object_hash,
    },
  }
  in

  {
    include [
      cups,
    ],
  }
