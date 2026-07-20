let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let glibc_fhs_patch_2_42 = {
    name = "glibc-fhs-patch-2.42",
    tag = "Source",
    object_hash = import "glibc-2.42-fhs-1.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "glibc/glibc-2.42-fhs-1.patch",
    },
  }
  in

  let glibc_src = {
    name = "glibc-src-2.42",
    tag = "Source",
    object_hash = "d1775e32e4628e64ef930f435b67bb63af7599acb6be2b335b9f19f16509f17f",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz",
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.42.tar.xz",
      ],
    },
  }
  in

  let glibc_bootstrap_rootfs = {
    name = "glibc-bootstrap-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs = {
      base = pkgs.buildpack_deps_rootfs,
      gawk = pkgs.gawk_gen1,
      bison = pkgs.bison_gen1,
    },
  }
  in

  let glibc_gen1 = {
    name = "glibc-gen1-2.42",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "libc_cv_slibdir=/usr/lib64",
        "--sbindir=/usr/bin",
        "--disable-nscd",
        "--without-selinux",
        "--enable-kernel=5.4",
      ],
      pre_configure = [
        {
          name = "apply_fhs_patch",
          run_as = "build-user",
          argv = [
            "patch",
            "-Np1",
            "-i",
            "@{fhs_patch}",
          ],
        },
        {
          name = "write_configparms",
          run_as = "build-user",
          argv = [
            "/bin/sh",
            "-ec",
            "mkdir -p \"@{build}/build\" && { echo \"rootsbindir=/usr/bin\"; echo \"sbindir=/usr/bin\"; } > \"@{build}/build/configparms\"",
          ],
        },
      ],
    },
    inputs = {
      _rootfs = glibc_bootstrap_rootfs,
      source = glibc_src,
      fhs_patch = glibc_fhs_patch_2_42,
    },
  }
  in

  let glibc = {
    name = "glibc-2.42",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "libc_cv_slibdir=/usr/lib64",
        "--sbindir=/usr/bin",
        "--disable-werror",
        "--enable-kernel=4.19",
        "--enable-stack-protector=strong",
        "--disable-nscd",
        "--without-selinux",
      ],
      pre_configure = [
        {
          name = "apply_fhs_patch",
          run_as = "build-user",
          argv = [
            "patch",
            "-Np1",
            "-i",
            "@{fhs_patch}",
          ],
        },
        {
          name = "write_configparms",
          run_as = "build-user",
          argv = [
            "/bin/sh",
            "-ec",
            "mkdir -p \"@{build}/build\" && { echo \"rootsbindir=/usr/bin\"; echo \"sbindir=/usr/bin\"; } > \"@{build}/build/configparms\"",
          ],
        },
      ],
      # ld.so.cache is a whole-system derived file: it is regenerated over the
      # complete image at finalize (ldconfig), so glibc must not ship its own
      # partial one -- otherwise it would be a stale cache in every rootfs and,
      # for the additive SandboxInstall finalize, an existing file the finalize
      # ldconfig would have to modify rather than add.
      post_install = {
        name = "drop_ld_so_cache",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          "rm -f @{out}/etc/ld.so.cache",
        ],
      },
    },
    inputs = {
      _rootfs = recipe.gen1_toolchain_rootfs pkgs "glibc-build-rootfs" [],
      source = glibc_src,
      fhs_patch = glibc_fhs_patch_2_42,
    },
  }
  in

  let glibc_libs =
    recipe.split.libs glibc "usr/lib64/*.so*"
    & {
      deps = {
        build = [],
        runtime = [],
      },
    }
  in

  {
    include [
      glibc_bootstrap_rootfs,
      glibc_gen1,
      glibc,
      glibc_libs,
    ],
  }
