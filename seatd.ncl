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

  # libseat + the seatd daemon. The logind backend (libseat over systemd-logind)
  # is enabled now that a logind session exists, so a compositor can take
  # devices via logind (LIBSEAT_BACKEND=logind). The seatd and builtin backends
  # are kept as fallbacks (LIBSEAT_BACKEND=seatd for the weston-start path).
  let seatd = {
    name = "seatd-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.systemd_dev,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dserver=enabled",
        "-Dlibseat-seatd=enabled",
        "-Dlibseat-builtin=enabled",
        "-Dlibseat-logind=systemd",
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
