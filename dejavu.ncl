let recipe = import "recipe-lib.ncl" in
let version = "2.37" in

fun pkgs =>
  let dejavu_src = {
    name = "dejavu-src-%{version}",
    tag = "Source",
    object_hash = "fa9ca4d13871dd122f61258a80d01751d603b4d3ee14095d65453b4e846e17d7",
    origin = {
      tag = "Http",
      url = "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-%{version}.tar.bz2",
    },
  }
  in

  let buildscript_dejavu = {
    name = "buildscript-dejavu",
    tag = "Source",
    object_hash = import "dejavu-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "dejavu-build.sh",
    },
  }
  in

  # A basic scalable font so cairo/fontconfig have something to render (Weston
  # panel/terminal), and a sensible default for the desktop later.
  let dejavu = {
    name = "dejavu-%{version}",
    tag = "SandboxBuild",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
      ],
      runtime = [],
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
      script = buildscript_dejavu,
      source = dejavu_src,
    },
  }
  in

  {
    include [
      buildscript_dejavu,
      dejavu,
    ],
  }
