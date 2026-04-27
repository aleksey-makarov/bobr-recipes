let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let glibc_fhs_patch_2_42 = {
    name = "glibc-fhs-patch-2.42",
    tag = "Source",
    object_hash = "b84d3ef28f8f0dd62db8b3d70cc65b5f7f4c9aa9affc7dcfa0d093df80d5f710",
    origin = {
      type = "http",
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/glibc-2.42-fhs-1.patch",
      unpack = false,
    },
    meta = {},
  }
  in

  let glibc_src = {
    name = "glibc-src-2.42",
    tag = "Source",
    object_hash = "fe4dd5420cafd78fd66805b9fe4b2f5c7e981a9f68410b3d273e2c5b355dbba4",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz",
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.42.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let glibc_bootstrap_image = {
    name = "glibc-bootstrap-image",
    tag = "Image",
    config =
      { ref_name | default = "glibc-bootstrap-image" }
      & {
        mode = "layered",
      },
    inputs = {
      base = pkgs.host_image,
      in000 = pkgs.gawk_gen1,
      in001 = pkgs.bison_gen1,
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
            "echo \"rootsbindir=/usr/sbin\" > \"@{build}/configparms\"",
          ],
        },
      ],
    },
    inputs = {
      image = glibc_bootstrap_image,
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
            "echo \"rootsbindir=/usr/sbin\" > \"@{build}/configparms\"",
          ],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_0,
      source = glibc_src,
      fhs_patch = glibc_fhs_patch_2_42,
    },
  }
  in

  {
    include [
      glibc_src,
      glibc_bootstrap_image,
      glibc_gen1,
      glibc,
    ],
  }
