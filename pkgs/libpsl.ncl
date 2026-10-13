# libpsl -- Public Suffix List library. libsoup 3 uses it for cookie-domain
# (public-suffix) checks. Meson build. Built without an IDNA runtime backend
# (-Druntime=no), so it pulls neither libidn2 nor ICU; the suffix list is
# embedded (builtin). python generates the DAFSA lookup table from the bundled
# list.
# Configure version and hash through `pkgs.libpsl_src`.
fun pkgs =>
  let libpsl_src = {
    version | default = "0.23.0",
    name = "libpsl-src-%{version}",
    tag = "Source",
    object_hash | default = "f39b9631b3d369a21259ea4654f8875c0ec6995ce9551c0eb5d423e4c011f911",
    origin = {
      tag = "Http",
      url = "https://github.com/rockdaboot/libpsl/releases/download/%{version}/libpsl-%{version}.tar.gz",
    },
  }
  in

  let libpsl = {
    name = "libpsl-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.python,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Druntime=no",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = pkgs.libpsl_src,
    },
  }
  in

  {
    include [
      libpsl_src,
      libpsl,
    ],
  }
