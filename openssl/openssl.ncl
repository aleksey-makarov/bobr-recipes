let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let openssl_src = fun version =>
    fun hash =>
    {
      name = "openssl-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://github.com/openssl/openssl/releases/download/openssl-%{version}/openssl-%{version}.tar.gz",
      },
    }
  in

  let buildscript_openssl = {
    name = "buildscript-openssl",
    tag = "Source",
    object_hash = import "openssl-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "openssl/openssl-build.sh",
    },
  }
  in

  let openssl = {
    version | default = "3.5.7",
    source_object_hash | default = "a8c0d28a529ca480f9f36cf5792e2cd21984552a3c8e4aa11a24aa31aeac98e8",
    name = "openssl-%{version}",
    tag = "SandboxInstallDeps",
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
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "/",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_openssl,
      source = openssl_src version source_object_hash,
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
      openssl,
      openssl_libs,
    ],
  }
