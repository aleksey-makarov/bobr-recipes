let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iana_etc_src = fun version => fun hash => {
    name = "iana-etc-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/Mic92/iana-etc/releases/download/%{version}/iana-etc-%{version}.tar.gz",
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
    version | default = "20250807",
    source_object_hash | default = "4f88470a2cac2a2f9568285aaff9aeaee0ab66c6ba3c12bba51adca915fa92b1",
    name = "iana-etc-%{version}",
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
      source = iana_etc_src version source_object_hash,
    },
  }
  in

  {
    include [
      buildscript_iana_etc,
      iana_etc,
    ],
  }
