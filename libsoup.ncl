# libsoup 3 -- GNOME HTTP client/server library. evolution-data-server uses it
# for its HTTP-based backends. Meson build. HTTP/2 via nghttp2, public-suffix
# checks via libpsl, cookie storage via sqlite, gzip via zlib. Brotli, GSSAPI,
# NTLM, sysprof, vala and docs are off. tls_check is off: glib-networking is not
# needed at compile time (it is a runtime dependency for TLS).
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = fun v =>
  let p = std.string.split "." v in
  "%{std.array.at 0 p}.%{std.array.at 1 p}"
in

fun pkgs =>
  let libsoup_src = fun version =>
    fun hash =>
      {
        name = "libsoup-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libsoup/%{series version}/libsoup-%{version}.tar.xz",
        },
      }
  in

  let libsoup = {
    version | default = "3.6.6",
    source_object_hash
      | default
      = "51ed0ae06f9d5a40f401ff459e2e5f652f9a510b7730e1359ee66d14d4872740",
    name = "libsoup-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.sqlite,
        pkgs.libpsl,
        pkgs.nghttp2,
        pkgs.zlib,
        pkgs.gobject_introspection,
        pkgs.gettext,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.sqlite,
        pkgs.libpsl,
        pkgs.nghttp2,
        pkgs.zlib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dbrotli=disabled",
        "-Dgssapi=disabled",
        "-Dntlm=disabled",
        "-Dsysprof=disabled",
        "-Dtls_check=false",
        "-Dvapi=disabled",
        "-Ddocs=disabled",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = libsoup_src version source_object_hash,
    },
  }
  in

  {
    include [
      libsoup,
    ],
  }
