let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let kmod_src = {
    version | default = "34.2",
    name = "kmod-src-%{version}",
    tag = "Source",
    object_hash | default = "5a5d5073070cc7e0c7a7a3c6ec2a0e1780850c8b47b3e3892226b93ffcb9cb54",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-%{version}.tar.xz",
    },
  }
  in

  let kmod = {
    name = "kmod-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.openssl,
        pkgs.xz,
        pkgs.zlib,
        pkgs.zstd,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.openssl_libs,
        pkgs.xz_libs,
        pkgs.zlib,
        pkgs.zstd,
      ],
    },
    config = {
      pre_configure = {
        name = "patch_requires_private",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i '/requires_private : libkmod_deps,/d' meson.build",
        ],
      },
      setup_args = [
        "--buildtype=release",
        "--sbindir=/usr/bin",
        # Install libs (and libkmod.pc) to /usr/lib, not the meson default
        # /usr/lib64: that is where pkg-config looks, so systemd's `-Dkmod`
        # can find libkmod and enable udev module autoloading.
        "--libdir=/usr/lib",
        "-Dmanpages=false",
      ],
    },
    inputs = {
      source = pkgs.kmod_src,
    },
  }
  in

  # Shared libkmod for runtime linkers (systemd-udevd's kmod builtin, the kmod
  # tools themselves). depends on the compression/crypto libs libkmod is built
  # against (see libkmod_deps in kmod's meson.build).
  let kmod_libs =
    recipe.split.libs
      pkgs.kmod
      [
        "usr/lib/libkmod.so*",
      ]
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.c_runtime,
          pkgs.openssl_libs,
          pkgs.xz_libs,
          pkgs.zstd,
          pkgs.zlib,
        ],
      },
    }
  in

  {
    include [
      kmod_src,
      kmod,
      kmod_libs,
    ],
  }
