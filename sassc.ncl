# sassc -- command-line wrapper around libsass. A build tool: libadwaita and GTK
# themes run sassc to compile their SCSS stylesheets to CSS. The git tag archive
# ships only configure.ac, so we regenerate configure with autoreconf. Links
# libsass.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let sassc_src = fun version =>
    fun hash =>
      {
        name = "sassc-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/sass/sassc/archive/refs/tags/%{version}.tar.gz",
        },
      }
  in

  let sassc = {
    version | default = "3.6.2",
    source_object_hash
      | default
      = "608dc9002b45a91d11ed59e352469ecc05e4f58fc1259fc9a9f5b8f0f8348a03",
    name = "sassc-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libsass,
        pkgs.automake,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libsass,
      ],
    },
    config = {
      pre_configure = {
        name = "autoreconf",
        run_as = "build-user",
        argv = ["/bin/sh", "-ec", "autoreconf -fi"],
      },
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = sassc_src version source_object_hash,
    },
  }
  in

  {
    include [
      sassc,
    ],
  }
