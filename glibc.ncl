let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let glibc_fhs_patch_2_42 =
    recipe.fetch "glibc-fhs-patch-2.42" {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/glibc-2.42-fhs-1.patch",
      hash = "md5:9a5997c3452909b1769918c759eff8a2",
      unpack = false,
    }
  in

  let glibc_src =
    recipe.fetch "glibc-src-2.42" {
      url = [
        "https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz",
        "https://mirrors.kernel.org/gnu/glibc/glibc-2.42.tar.xz",
      ],
      hash = "md5:23c6f5a27932b435cae94e087cb8b1f5",
    }
  in

  let glibc_bootstrap_image =
    recipe.image "glibc-bootstrap-image" {
      mode = "layered",
    } pkgs.host_image [pkgs.gawk_gen1, pkgs.bison_gen1]
  in

  let glibc_gen1 =
    recipe.binary "glibc-gen1-2.42" {
      script_config = {
        build_dir = "build",
        pre_configure = m%"
          patch -Np1 -i /in/sources1
          mkdir -p build
          echo "rootsbindir=/usr/sbin" > build/configparms
        "%,
        configure_args = [
          "libc_cv_slibdir=/usr/lib64",
          "--disable-nscd",
          "--without-selinux",
          "--enable-kernel=5.4",
        ],
      },
    } glibc_bootstrap_image pkgs.buildscript_autotools [glibc_src, glibc_fhs_patch_2_42]
  in

  let glibc =
    recipe.binary "glibc-2.42" {
      script_config = {
        build_dir = "build",
        pre_configure = m%"
          patch -Np1 -i /in/sources1
          mkdir -p build
          echo "rootsbindir=/usr/sbin" > build/configparms
        "%,
        configure_args = [
          "libc_cv_slibdir=/usr/lib64",
          "--disable-werror",
          "--enable-kernel=4.19",
          "--enable-stack-protector=strong",
          "--disable-nscd",
          "--without-selinux",
        ],
      },
    } pkgs.system_image_0 pkgs.buildscript_autotools [glibc_src, glibc_fhs_patch_2_42]
  in

  {
    include [
      glibc_src,
      glibc_bootstrap_image,
      glibc_gen1,
      glibc,
    ],
  }
