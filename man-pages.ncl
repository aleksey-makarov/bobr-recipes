let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_pages_src = fun version => fun hash => {
    name = "man-pages-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/docs/man-pages/man-pages-%{version}.tar.xz",
    },
  }
  in

  let buildscript_man_pages = {
    name = "buildscript-man-pages",
    tag = "Source",
    object_hash = import "man-pages-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "man-pages-build.sh",
    },
  }
  in

  let man_pages = {
    version | default = "6.15",
    source_object_hash | default = "03d8ebf618bd5df57cb4bf355efa3f4cd3a00b771efd623d4fd042b5dceb4465",
    name = "man-pages-%{version}",
    tag = "SandboxBuild",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
        pkgs.make,
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
      script = buildscript_man_pages,
      source = man_pages_src version source_object_hash,
    },
  }
  in

  {
    include [
      buildscript_man_pages,
      man_pages,
    ],
  }
