let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let e2fsprogs_src = fun version => fun hash => {
    name = "e2fsprogs-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v%{version}/e2fsprogs-%{version}.tar.gz",
    },
  }
  in

  let buildscript_e2fsprogs = {
    name = "buildscript-e2fsprogs",
    tag = "Source",
    object_hash = import "e2fsprogs-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "e2fsprogs/e2fsprogs-build.sh",
    },
  }
  in

  let e2fsprogs = {
    version | default = "1.47.3",
    source_object_hash | default = "2f5164e64dd7d91eadd1e0e8a77d92c06dd7837bb19f1d9189ce1939b363d2b4",
    name = "e2fsprogs-%{version}",
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
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "/",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_e2fsprogs,
      source = e2fsprogs_src version source_object_hash,
    },
  }
  in

  {
    include [
      e2fsprogs,
    ],
  }
