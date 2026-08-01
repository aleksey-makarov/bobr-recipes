fun pkgs =>
  let qemu_src = fun version => fun hash => {
    name = "qemu-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://download.qemu.org/qemu-%{version}.tar.xz",
    },
  }
  in

  # Host-side system emulator for the x86-64 development images. This is a
  # deliberately focused KVM build: no TCG fallback and no remote/UI stacks
  # other than SDL-on-Wayland with virglrenderer.
  let qemu = {
    version | default = "11.0.3",
    source_object_hash | default = "da5fcffc32762820568b828ed430a728864d34d50b6d2f30358597760cbb0523",
    name = "qemu-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.python,
        pkgs.python_setuptools,
        pkgs.python_wheel,
        pkgs.meson,
        pkgs.ninja,
        pkgs.flex,
        pkgs.bison,
        pkgs.glib,
        pkgs.zlib,
        pkgs.bzip2,
        pkgs.zstd,
        pkgs.libpng,
        pkgs.pixman,
        pkgs.libslirp,
        pkgs.sdl2_compat,
        pkgs.libepoxy_host,
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.virglrenderer,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.zlib,
        pkgs.bzip2,
        pkgs.zstd,
        pkgs.libpng,
        pkgs.pixman,
        pkgs.libslirp,
        pkgs.sdl2_compat,
        pkgs.libepoxy_host,
        pkgs.libdrm_libs,
        pkgs.mesa,
        pkgs.virglrenderer,
      ],
    },
    config = {
      configure_args = [
        "--target-list=x86_64-softmmu",
        "--libdir=/usr/lib",
        "--sysconfdir=/etc",
        "--localstatedir=/var",
        "--enable-kvm",
        "--disable-tcg",
        "--enable-tools",
        "--enable-bzip2",
        "--enable-zstd",
        "--enable-png",
        "--enable-sdl",
        "--disable-sdl-image",
        "--enable-opengl",
        "--enable-virglrenderer",
        "--enable-slirp",
        "--disable-slirp-smbd",
        "--disable-download",
        "--disable-relocatable",
        "--disable-modules",
        "--disable-plugins",
        "--disable-docs",
        "--disable-guest-agent",
        "--disable-dbus-display",
        "--disable-gtk",
        "--disable-vnc",
        "--disable-spice",
        "--disable-curses",
        "--disable-passt",
        "--audio-drv-list=",
        "--disable-oss",
        "--disable-fdt",
        "--disable-capstone",
        "--disable-strip",
        "--disable-werror",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -x /usr/bin/qemu-system-x86_64
            test -x /usr/bin/qemu-img
            test -d /usr/share/qemu
          "%,
        ],
      },
    },
    inputs = {
      source = qemu_src version source_object_hash,
    },
  }
  in

  {
    include [qemu],
  }
