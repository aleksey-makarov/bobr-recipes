let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dejagnu_src = {
    name = "dejagnu-src-1.6.3",
    tag = "Source",
    object_hash = "18edf6477404a75c1ea7e0e76910d9c88c9adb52d8eb82c6a5d5f79bb69fb0c9",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz",
        "https://mirrors.kernel.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz",
      ],
    },
  }
  in

  let buildscript_dejagnu = {
    name = "buildscript-dejagnu",
    tag = "Source",
    object_hash = import "dejagnu-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "dejagnu-build.sh",
    },
  }
  in

  let dejagnu = {
    name = "dejagnu-1.6.3",
    tag = "SandboxBuild",
    deps = {
      build = [
        pkgs.linux_headers,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.make,
        pkgs.coreutils,
        pkgs.gawk,
        pkgs.sed,
        pkgs.grep,
        pkgs.findutils,
        pkgs.diffutils,
        pkgs.tcl,
        pkgs.expect,
        pkgs.texinfo,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.expect,
        pkgs.tcl,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_dejagnu,
      source = dejagnu_src,
    },
  }
  in

  {
    include [
      buildscript_dejagnu,
      dejagnu,
    ],
  }
