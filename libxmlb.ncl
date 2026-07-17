# libxmlb -- library for querying compiled XML documents (a binary blob format).
# A dependency of AppStream (it stores the metadata pool as an xmlb blob). Meson
# build; links glib, liblzma (xz) and libzstd for the compressed blobs. The CLI
# tool, gtk-doc, introspection, the Snowball stemmer and tests are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libxmlb_src = fun version =>
    fun hash =>
      {
        name = "libxmlb-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/hughsie/libxmlb/releases/download/%{version}/libxmlb-%{version}.tar.xz",
        },
      }
  in

  let libxmlb = {
    version | default = "0.3.28",
    source_object_hash
      | default
      = "5982b4fe344deb36e57b40d7582f594ecd9414f86fb8258bb56f8b1a38e1d527",
    name = "libxmlb-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.xz,
        pkgs.zstd,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.xz,
        pkgs.zstd,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dgtkdoc=false",
        "-Dintrospection=false",
        "-Dtests=false",
        "-Dstemmer=false",
        "-Dcli=false",
        "-Dlzma=enabled",
        "-Dzstd=enabled",
      ],
    },
    inputs = {
      source = libxmlb_src version source_object_hash,
    },
  }
  in

  {
    include [
      libxmlb,
    ],
  }
