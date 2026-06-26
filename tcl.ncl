let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tcl_src = {
    name = "tcl-src-8.6.16",
    tag = "Source",
    object_hash = "29af15338ae522c3da77be6961ad094dcb3c8436543b5327a58c2d0f6f3c70cc",
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.16/tcl8.6.16-src.tar.gz",
        "https://sourceforge.net/projects/tcl/files/Tcl/8.6.16/tcl8.6.16-src.tar.gz/download",
      ],
    },
  }
  in

  let buildscript_tcl = {
    name = "buildscript-tcl",
    tag = "Source",
    object_hash = import "tcl-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tcl-build.sh",
    },
  }
  in

  let tcl = {
    name = "tcl-8.6.16",
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
      ],
      runtime = [
        pkgs.glibc_libs,
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
      script = buildscript_tcl,
      source = tcl_src,
    },
  }
  in

  {
    include [
      buildscript_tcl,
      tcl,
    ],
  }
