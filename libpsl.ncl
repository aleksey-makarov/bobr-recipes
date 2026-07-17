# libpsl -- Public Suffix List library. libsoup 3 uses it for cookie-domain
# (public-suffix) checks. Meson build. Built without an IDNA runtime backend
# (-Druntime=no), so it pulls neither libidn2 nor ICU; the suffix list is
# embedded (builtin). python generates the DAFSA lookup table from the bundled
# list. `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libpsl_src = fun version =>
    fun hash =>
      {
        name = "libpsl-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/rockdaboot/libpsl/releases/download/%{version}/libpsl-%{version}.tar.gz",
        },
      }
  in

  let libpsl = {
    version | default = "0.23.0",
    source_object_hash
      | default
      = "f39b9631b3d369a21259ea4654f8875c0ec6995ce9551c0eb5d423e4c011f911",
    name = "libpsl-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.python,
      ],
      runtime = [
        pkgs.glibc_libs,
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
      source = libpsl_src version source_object_hash,
    },
  }
  in

  {
    include [
      libpsl,
    ],
  }
