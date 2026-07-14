# evolution-data-server -- GNOME's calendar/addressbook/mail data backends.
# gnome-shell links libecal-2.0 and libedataserver-1.2 (its calendar and clock).
# CMake project, built via the Makefile builder with a cmake_configure pre-step.
# We build the non-GUI data libraries only: the GTK3/GTK4 UI libs, WebKitGTK
# OAuth2, GNOME Online Accounts, the weather backend (libgweather), Berkeley DB,
# vala bindings, docs and tests are all off -- dropping those dependencies. TLS
# goes through GIO (glib-networking) at runtime, and NSS/krb5/phonenumber are
# auto-detected (absent, hence inert), so no heavy crypto stack is pulled in.
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = fun v =>
  let p = std.string.split "." v in
  "%{std.array.at 0 p}.%{std.array.at 1 p}"
in

fun pkgs =>
  let eds_src = fun version =>
    fun hash =>
      {
        name = "evolution-data-server-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/evolution-data-server/%{series version}/evolution-data-server-%{version}.tar.xz",
        },
      }
  in

  let evolution_data_server = {
    version | default = "3.56.2",
    source_object_hash
      | default
      = "df4ec29950f29a76eac6fbe0f814c48d2cef7d3fdb905002a4a883dd761ce93c",
    name = "evolution-data-server-%{version}",
    tag = "Makefile",
    deps = {
      build = [
        pkgs.cmake,
        pkgs.glib,
        pkgs.libsoup,
        pkgs.libical,
        pkgs.libsecret,
        pkgs.libxml2,
        pkgs.sqlite,
        pkgs.icu,
        pkgs.zlib,
        pkgs.nspr,
        pkgs.nss,
        pkgs.util_linux,
        pkgs.json_glib,
        pkgs.gobject_introspection,
        pkgs.gettext,
        pkgs.gperf,
        pkgs.python,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libsoup,
        pkgs.libical,
        pkgs.libsecret,
        pkgs.libxml2,
        pkgs.sqlite,
        pkgs.icu,
        pkgs.zlib,
        pkgs.nspr,
        pkgs.nss,
        pkgs.util_linux_libs,
        pkgs.json_glib,
      ],
    },
    config = {
      pre_build = {
        name = "cmake_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DENABLE_GTK=OFF -DENABLE_GTK4=OFF -DENABLE_GOA=OFF -DENABLE_WEATHER=OFF -DENABLE_OAUTH2_WEBKITGTK=OFF -DENABLE_OAUTH2_WEBKITGTK4=OFF -DWITH_LIBDB=OFF -DWITH_KRB5=OFF -DWITH_OPENLDAP=OFF -DENABLE_CANBERRA=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTS=OFF -DENABLE_INSTALLED_TESTS=OFF -DENABLE_GTK_DOC=OFF -DENABLE_VALA_BINDINGS=OFF -DENABLE_INTROSPECTION=ON",
        ],
      },
    },
    inputs = {
      source = eds_src version source_object_hash,
    },
  }
  in

  {
    include [
      evolution_data_server,
    ],
  }
