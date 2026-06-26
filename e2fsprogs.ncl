let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let e2fsprogs_src = {
    name = "e2fsprogs-src-1.47.3",
    tag = "Source",
    object_hash = "23ada8c7f6b8b50ab0ba770bc662ab0c99243972aaccf34114ce1db02692583a",
    origin = {
      tag = "Http",
      url = "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.gz",
    },
  }
  in

  let buildscript_e2fsprogs = {
    name = "buildscript-e2fsprogs",
    tag = "Source",
    object_hash = import "e2fsprogs-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "e2fsprogs-build.sh",
    },
  }
  in

  let e2fsprogs = {
    name = "e2fsprogs-1.47.3",
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
        pkgs.pkgconf,
        pkgs.util_linux,
        pkgs.texinfo,
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
      script = buildscript_e2fsprogs,
      source = e2fsprogs_src,
    },
  }
  in

  {
    include [
      buildscript_e2fsprogs,
      e2fsprogs,
    ],
  }
