let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dejagnu_src = {
    name = "dejagnu-src-1.6.3",
    tag = "Source",
    object_hash = "87daefacd7958b4a69f88c6856dbd1634261963c414079d0c371f589cd66a2e3",
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
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "@{out}",
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
