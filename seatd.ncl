let version = "0.9.3" in

fun pkgs =>
  let seatd_src = {
    name = "seatd-src-%{version}",
    tag = "Source",
    object_hash = "ed9508055345610bd166f9bcae6fa678fc206284d40480fa62fff4d10e21079d",
    origin = {
      tag = "Http",
      url = "https://git.sr.ht/~kennylevinsen/seatd/archive/%{version}.tar.gz",
    },
  }
  in

  # libseat + the seatd daemon. For step 3 we use the seatd backend (no logind
  # yet); the logind backend is disabled and will be enabled once PAM/logind
  # land. builtin backend kept as a fallback.
  let seatd = {
    name = "seatd-%{version}",
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
        "-Dserver=enabled",
        "-Dlibseat-seatd=enabled",
        "-Dlibseat-builtin=enabled",
        "-Dlibseat-logind=disabled",
        "-Dman-pages=disabled",
        "-Dexamples=disabled",
      ],
    },
    inputs = {
      source = seatd_src,
    },
  }
  in

  {
    include [
      seatd,
    ],
  }
