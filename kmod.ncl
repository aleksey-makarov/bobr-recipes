let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kmod_src = {
    name = "kmod-src-34.2",
    tag = "Source",
    object_hash = "5a5d5073070cc7e0c7a7a3c6ec2a0e1780850c8b47b3e3892226b93ffcb9cb54",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz",
    },
  }
  in

  let kmod = {
    name = "kmod-34.2",
    tag = "Meson",
    deps = {
      build = [
        pkgs.openssl,
        pkgs.zstd,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.openssl_libs,
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
      source = kmod_src,
    },
  }
  in

  # Shared libkmod for runtime linkers (systemd-udevd's kmod builtin, the kmod
  # tools themselves). depends on the compression/crypto libs libkmod is built
  # against (see libkmod_deps in kmod's meson.build).
  let kmod_libs =
    recipe.split.libs kmod [
      "usr/lib/libkmod.so*",
    ]
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
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
      kmod,
      kmod_libs,
    ],
  }
