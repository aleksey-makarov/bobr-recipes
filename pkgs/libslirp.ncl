fun pkgs =>
  let libslirp_src = fun version => fun hash => {
    name = "libslirp-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://gitlab.freedesktop.org/slirp/libslirp/-/archive/v%{version}/libslirp-v%{version}.tar.gz",
    },
  }
  in

  let libslirp = {
    version | default = "4.9.3",
    source_object_hash | default = "ee698ca4ce05217ca7d520c7f0b1b1228fd7d32922dd32d1051c347152588417",
    name = "libslirp-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
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
          "printf '%s\\n' '%{version}' > .tarball-version",
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
      source = libslirp_src version source_object_hash,
    },
  }
  in

  {
    include [libslirp],
  }
