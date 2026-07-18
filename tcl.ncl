let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tcl_src = fun version => fun hash => {
    name = "tcl-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/tcl/Tcl/%{version}/tcl%{version}-src.tar.gz",
        "https://sourceforge.net/projects/tcl/files/Tcl/%{version}/tcl%{version}-src.tar.gz/download",
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
    version | default = "8.6.16",
    source_object_hash | default = "91cb8fa61771c63c262efb553059b7c7ad6757afa5857af6265e4b0bdc2a14a5",
    name = "tcl-%{version}",
    tag = "SandboxInstallBuild",
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
            BOBR_INSTALL_DIR = "/",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_tcl,
      source = tcl_src version source_object_hash,
    },
  }
  in

  {
    include [
      tcl,
    ],
  }
