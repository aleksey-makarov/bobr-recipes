let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_pages_src = {
    name = "man-pages-src-6.15",
    tag = "Source",
    object_hash = "03d8ebf618bd5df57cb4bf355efa3f4cd3a00b771efd623d4fd042b5dceb4465",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.15.tar.xz",
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
    name = "man-pages-6.15",
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
      source = man_pages_src,
    },
  }
  in

  {
    include [
      buildscript_man_pages,
      man_pages,
    ],
  }
