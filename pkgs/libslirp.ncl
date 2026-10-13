fun pkgs =>
  # Configure version and hash through pkgs.libslirp_src.
  let libslirp_src = {
    version | default = "4.9.3",
    name = "libslirp-src-%{version}",
    tag = "Source",
    object_hash | default = "ee698ca4ce05217ca7d520c7f0b1b1228fd7d32922dd32d1051c347152588417",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/slirp/libslirp/-/archive/v%{version}/libslirp-v%{version}.tar.gz",
    },
  }
  in

  let libslirp = {
    name = "libslirp-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
      ],
    },
    config = {
      pre_configure = {
        name = "record_tarball_version",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "printf '%s\\n' '%{inputs.source.version}' > .tarball-version",
        ],
      },
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          "test -s /usr/lib/libslirp.so.0 && test -s /usr/lib/pkgconfig/slirp.pc",
        ],
      },
    },
    inputs = {
      source = pkgs.libslirp_src,
    },
  }
  in

  {
    include [libslirp, libslirp_src],
  }
