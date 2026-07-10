# libxcvt -- VESA CVT timing library, split out of xorg-server so Wayland
# compositors can generate mode timings without X. mutter's native backend
# needs its `cvt` program at build time to generate the default-modes table;
# the library itself is not linked. `version`/`hashes` are node fields
# (overridable), as in linux.ncl.
let default_version = "0.1.3" in
let default_hashes = {
  "0.1.3" = "a929998a8767de7dfa36d6da4751cdbeef34ed630714f2f4a767b351f2442e01",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libxcvt-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.x.org/releases/individual/lib/libxcvt-%{version}.tar.xz",
        },
      }
  in

  let libxcvt = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "libxcvt-%{version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
    },
    inputs = {
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libxcvt,
    ],
  }
