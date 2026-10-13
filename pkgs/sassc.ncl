# sassc -- command-line wrapper around libsass. A build tool: libadwaita and GTK
# themes run sassc to compile their SCSS stylesheets to CSS. The git tag archive
# ships only configure.ac, so we regenerate configure with autoreconf. Links
# libsass.
# Configure version and hash through `pkgs.sassc_src`.
fun pkgs =>
  let sassc_src = {
    version | default = "3.6.2",
    name = "sassc-src-%{version}",
    tag = "Source",
    object_hash | default = "608dc9002b45a91d11ed59e352469ecc05e4f58fc1259fc9a9f5b8f0f8348a03",
    origin = {
      tag = "Http",
      url = "https://github.com/sass/sassc/archive/refs/tags/%{version}.tar.gz",
    },
  }
  in

  let sassc = {
    name = "sassc-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libsass,
        pkgs.automake,
        pkgs.libtool,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
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
      source = pkgs.sassc_src,
    },
  }
  in

  {
    include [
      sassc_src,
      sassc,
    ],
  }
