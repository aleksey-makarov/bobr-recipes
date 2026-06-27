let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iana_etc_src = {
    name = "iana-etc-src-20250807",
    tag = "Source",
    object_hash = "0b860de93a69527dd8b72156779c94e324b66831b89853a0b4ea672c21a8a431",
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
