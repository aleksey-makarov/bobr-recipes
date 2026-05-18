let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let glibc_fhs_patch_2_42 = {
    name = "glibc-fhs-patch-2.42",
    tag = "Source",
    object_hash = "b84d3ef28f8f0dd62db8b3d70cc65b5f7f4c9aa9affc7dcfa0d093df80d5f710",
    origin = {
      type = "http",
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/glibc-2.42-fhs-1.patch",
    },
  }
  in

  let glibc_src = {
    name = "glibc-src-2.42",
    tag = "Source",
    object_hash = "1fd37aa7476218a0f497a3d81e5434243d7aa0abe4f6f014a64190448431f205",
    origin = {
      type = "http",
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
    tag = "Autotools",
    config = {
      configure_args = [
        "libc_cv_slibdir=/usr/lib64",
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
            "mkdir -p \"@{build}/build\" && echo \"rootsbindir=/usr/sbin\" > \"@{build}/build/configparms\"",
          ],
        },
      ],
    },
    inputs = {
      rootfs = glibc_bootstrap_rootfs,
      source = glibc_src,
      fhs_patch = glibc_fhs_patch_2_42,
    },
  }
  in

  let glibc = {
    name = "glibc-2.42",
    tag = "Autotools",
    config = {
      configure_args = [
        "libc_cv_slibdir=/usr/lib64",
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
            "mkdir -p \"@{build}/build\" && echo \"rootsbindir=/usr/sbin\" > \"@{build}/build/configparms\"",
          ],
        },
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_0,
      source = glibc_src,
      fhs_patch = glibc_fhs_patch_2_42,
    },
  }
  in

  {
    include [
      glibc_src,
      glibc_bootstrap_rootfs,
      glibc_gen1,
      glibc,
    ],
  }
