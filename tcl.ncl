let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tcl_src = {
    name = "tcl-src-8.6.16",
    tag = "Source",
    object_hash = "91cb8fa61771c63c262efb553059b7c7ad6757afa5857af6265e4b0bdc2a14a5",
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
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "@{out}",
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
