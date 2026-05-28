let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let buildscript_perl_configure = {
    name = "buildscript-perl-configure",
    tag = "Source",
    object_hash = import "perl-configure.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "perl-configure.sh",
    },
  }
  in

  let perl_src = {
    name = "perl-src-5.42.0",
    tag = "Source",
    object_hash = "ce0aace744ab7aeb6f42594af5afb7044b14377a6e16bb2be20dd50492926e90",
    origin = {
      tag = "Http",
      url = "https://www.cpan.org/src/5.0/perl-5.42.0.tar.xz",
    },
  }
  in

  let perl_build_rootfs = {
    name = "perl-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.bzip2,
        pkgs.less,
      ],
  }
  in

  let perl = {
    name = "perl-5.42.0",
    tag = "SandboxBuildRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.bzip2,
        pkgs.zlib,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "configure"],
          env = { MBUILD_SOURCE_DIR = "@{build}/source" },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "build"],
          env = { MBUILD_SOURCE_DIR = "@{build}/source" },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "install"],
          env = { MBUILD_SOURCE_DIR = "@{build}/source" },
        },
      ],
    },
    inputs = {
      rootfs = perl_build_rootfs,
      script = buildscript_perl_configure,
      source = perl_src,
    },
  }
  in

  {
    include [
      perl_src,
      perl,
    ],
  }
