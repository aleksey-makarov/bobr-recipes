let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let openssl_src = {
    name = "openssl-src-3.5.2",
    tag = "Source",
    object_hash = "3cba3886442fef568c647ca135acd74fcd6c469b1e49f61bca38b1eaa60bfe9d",
    origin = {
      tag = "Http",
      url = "https://github.com/openssl/openssl/releases/download/openssl-3.5.2/openssl-3.5.2.tar.gz",
    },
  }
  in

  let buildscript_openssl = {
    name = "buildscript-openssl",
    tag = "Source",
    object_hash = import "openssl-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "openssl-build.sh",
    },
  }
  in

  let openssl = {
    name = "openssl-3.5.2",
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
        pkgs.perl,
        pkgs.zlib,
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
      script = buildscript_openssl,
      source = openssl_src,
    },
  }
  in

  let openssl_libs =
    recipe.split.libs openssl "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      buildscript_openssl,
      openssl,
      openssl_libs,
    ],
  }
