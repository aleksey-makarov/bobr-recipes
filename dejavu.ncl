let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dejavu_src = fun version => fun hash => {
    name = "dejavu-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "2.37",
    source_object_hash | default = "fa9ca4d13871dd122f61258a80d01751d603b4d3ee14095d65453b4e846e17d7",
    name = "dejavu-%{version}",
    tag = "SandboxInstallBuild",
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
            BOBR_INSTALL_DIR = "/",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_dejavu,
      source = dejavu_src version source_object_hash,
    },
  }
  in

  {
    include [
      dejavu,
    ],
  }
