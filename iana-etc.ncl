let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iana_etc_src = {
    name = "iana-etc-src-20250807",
    tag = "Source",
    object_hash = "4f88470a2cac2a2f9568285aaff9aeaee0ab66c6ba3c12bba51adca915fa92b1",
    origin = {
      tag = "Http",
      url = "https://github.com/Mic92/iana-etc/releases/download/20250807/iana-etc-20250807.tar.gz",
    },
  }
  in

  let buildscript_iana_etc = {
    name = "buildscript-iana-etc",
    tag = "Source",
    object_hash = import "iana-etc-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "iana-etc-build.sh",
    },
  }
  in

  let iana_etc = {
    name = "iana-etc-20250807",
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
      script = buildscript_iana_etc,
      source = iana_etc_src,
    },
  }
  in

  {
    include [
      buildscript_iana_etc,
      iana_etc,
    ],
  }
