let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let system_image_0 = {
    name = "system-image-0",
    tag = "Image",
    config =
      { ref_name | default = "system-image-0" }
      & {
        mode = "bootstrap",
      },
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
        pkgs.glibc_gen1,
        pkgs.binutils_gen1,
        pkgs.gcc_gen1,
        pkgs.bash_gen1,
        pkgs.gawk_gen1,
        pkgs.bison_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
        pkgs.tar_gen1,
        pkgs.patch_gen1,
        pkgs.findutils_gen1,
        pkgs.diffutils_gen1,
        pkgs.m4_gen1,
        pkgs.python_gen1,
      ],
  }
  in

  let system_rootfs_0 = {
    name = "system-rootfs-0",
    tag = "Rootfs",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
        pkgs.glibc_gen1,
        pkgs.binutils_gen1,
        pkgs.gcc_gen1,
        pkgs.bash_gen1,
        pkgs.gawk_gen1,
        pkgs.bison_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
        pkgs.tar_gen1,
        pkgs.patch_gen1,
        pkgs.findutils_gen1,
        pkgs.diffutils_gen1,
        pkgs.m4_gen1,
        pkgs.python_gen1,
      ],
  }
  in

  let system_image_1 = {
    name = "system-image-1",
    tag = "Image",
    config =
      { ref_name | default = "system-image-1" }
      & {
        mode = "bootstrap",
      },
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.bash_gen1,
        pkgs.gawk_gen1,
        pkgs.bison_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
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
    tag = "Rootfs",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.bash_gen1,
        pkgs.gawk_gen1,
        pkgs.bison_gen1,
        pkgs.make_gen1,
        pkgs.coreutils_gen1,
        pkgs.sed_gen1,
        pkgs.grep_gen1,
        pkgs.gzip_gen1,
        pkgs.tar_gen1,
        pkgs.patch_gen1,
        pkgs.findutils_gen1,
        pkgs.diffutils_gen1,
        pkgs.m4_gen1,
        pkgs.python_gen1,
      ],
  }
  in

  let system_image_2 = {
    name = "system-image-2",
    tag = "Image",
    config =
      { ref_name | default = "system-image-2" }
      & {
        mode = "bootstrap",
      },
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
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

  let system_rootfs_2 = {
    name = "system-rootfs-2",
    tag = "Rootfs",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
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

  let system_image = {
    name = "system-image",
    tag = "Image",
    config = { ref_name | default = "system-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.autoconf,
        pkgs.bzip2,
        pkgs.ncurses,
        pkgs.perl,
        pkgs.pkgconf,
        pkgs.python,
        pkgs.expat,
        pkgs.libffi,
      ],
  }
  in

  let system_rootfs = {
    name = "system-rootfs",
    tag = "Rootfs",
    config = {},
    inputs =
      recipe.numbered_inputs [
        pkgs.base_filesystem,
        pkgs.linux_headers,
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
        pkgs.tar,
        pkgs.patch,
        pkgs.findutils,
        pkgs.diffutils,
        pkgs.m4,
        pkgs.bc,
        pkgs.flex,
        pkgs.zlib,
        pkgs.elfutils,
        pkgs.autoconf,
        pkgs.bzip2,
        pkgs.ncurses,
        pkgs.perl,
        pkgs.pkgconf,
        pkgs.python,
        pkgs.expat,
        pkgs.libffi,
      ],
  }
  in

  {
    include [
      system_image_0,
      system_rootfs_0,
      system_image_1,
      system_rootfs_1,
      system_image_2,
      system_rootfs_2,
      system_image,
      system_rootfs,
    ],
  }
