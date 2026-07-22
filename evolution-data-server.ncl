let recipe = import "recipe-lib.ncl" in
# evolution-data-server -- GNOME's calendar/addressbook/mail data backends.
# gnome-shell links libecal-2.0 and libedataserver-1.2 (its calendar and clock).
# CMake project, built with the Cmake builder.
# We build the non-GUI data libraries only: the GTK3/GTK4 UI libs, WebKitGTK
# OAuth2, GNOME Online Accounts, the weather backend (libgweather), Berkeley DB,
# vala bindings, docs and tests are all off -- dropping those dependencies. TLS
# goes through GIO (glib-networking) at runtime, and NSS/krb5/phonenumber are
# auto-detected (absent, hence inert), so no heavy crypto stack is pulled in.
# `version`/`source_object_hash`/`series` are node fields (overridable).
let series = recipe.version_prefix 2 in

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
    tag = "Cmake",
    deps = {
      build = [
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
        # g-ir-scanner imports distutils (gone in 3.13); setuptools provides it.
        pkgs.python_setuptools,
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
      # Build single-threaded: EDS's gettext handling races under parallel make
      # -- msgmerge rewrites po/*.po while `msgfmt --desktop` reads them to build
      # the translated .desktop, so msgfmt intermittently sees a half-written
      # as.po ("end-of-file within string"). The builder runs `make -j<nproc>
      # <make_args>`; a trailing -j1 wins (GNU make honours the last -j).
      make_args = ["-j1"],
      cmake_args = [
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DENABLE_GTK=OFF",
        "-DENABLE_GTK4=OFF",
        "-DENABLE_GOA=OFF",
        "-DENABLE_WEATHER=OFF",
        "-DENABLE_OAUTH2_WEBKITGTK=OFF",
        "-DENABLE_OAUTH2_WEBKITGTK4=OFF",
        "-DWITH_LIBDB=OFF",
        "-DWITH_KRB5=OFF",
        "-DWITH_OPENLDAP=OFF",
        "-DENABLE_CANBERRA=OFF",
        "-DENABLE_EXAMPLES=OFF",
        "-DENABLE_TESTS=OFF",
        "-DENABLE_INSTALLED_TESTS=OFF",
        "-DENABLE_GTK_DOC=OFF",
        "-DENABLE_VALA_BINDINGS=OFF",
        "-DENABLE_INTROSPECTION=ON",
      ],
      # Without DESTDIR (the SandboxInstall model installs into the live overlay
      # root), EDS's CMake install runs glib-compile-schemas and ships
      # gschemas.compiled. Packages must not ship that cache: it is a
      # whole-system derived file that gnome-finalize regenerates. Drop the
      # cache we just created (an upper-only removal, so the layer stays
      # additive); the schema .xml files are still shipped.
      post_install = {
        name = "drop_glib_schema_cache",
        run_as = "root",
        argv = ["rm", "-fv", "/usr/share/glib-2.0/schemas/gschemas.compiled"],
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
