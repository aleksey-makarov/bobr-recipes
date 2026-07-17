
fun pkgs =>
  let seatd_src = fun version => fun hash => {
    name = "seatd-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "0.9.3",
    source_object_hash | default = "302564d54d8e28191fadfd734f2675ecb0c9e0615a58011b89ef15dfa4dbaa96",
    name = "seatd-%{version}",
    tag = "MesonInstall",
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
      source = seatd_src version source_object_hash,
    },
  }
  in

  {
    include [
      seatd,
    ],
  }
