let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let system_rootfs_0 = {
    name = "system-rootfs-0",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers_gen1,
        pkgs.glibc_gen1,
        pkgs.binutils_gen1,
        pkgs.gcc_gen1,
        pkgs.bash_gen1,
        pkgs.gawk_gen1,
        pkgs.awk_symlink,
        pkgs.bison_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
        pkgs.xz_gen1,
        pkgs.tar_gen1,
        pkgs.patch_gen1,
        pkgs.findutils_gen1,
        pkgs.diffutils_gen1,
        pkgs.m4_gen1,
        pkgs.python_gen1,
      ],
  }
  in

  let system_rootfs_1 = {
    name = "system-rootfs-1",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers_gen1,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.bash_gen1,
        pkgs.gawk_gen1,
        pkgs.awk_symlink,
        pkgs.bison_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
        pkgs.xz_gen1,
        pkgs.tar_gen1,
        pkgs.patch_gen1,
        pkgs.findutils_gen1,
        pkgs.diffutils_gen1,
        pkgs.m4_gen1,
        pkgs.python_gen1,
      ],
  }
  in

  let system_rootfs_2 = {
    name = "system-rootfs-2",
    tag = "TreeMerge",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers_gen1,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.bash,
        pkgs.gawk,
        pkgs.bison,
        pkgs.make,
        pkgs.coreutils,
        pkgs.sed,
        pkgs.grep,
        pkgs.gzip,
        pkgs.xz_gen1,
        pkgs.tar,
        pkgs.patch,
        pkgs.findutils,
        pkgs.diffutils,
        pkgs.m4,
        pkgs.bc,
        pkgs.flex,
        pkgs.zlib,
        pkgs.elfutils,
      ],
  }
  in

  {
    include [
      system_rootfs_0,
      system_rootfs_1,
      system_rootfs_2,
    ],
  }
