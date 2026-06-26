let recipe = import "recipe-lib.ncl" in
let hashes = {
  "3.5.2" = "3cba3886442fef568c647ca135acd74fcd6c469b1e49f61bca38b1eaa60bfe9d",
  "3.5.7" = "33845dfc342f1a135108c246dee86cbe77d09bde3b58e5e1e272c37da80392b4",
} in

fun pkgs =>
  let openssl_src = fun version => {
    name = "openssl-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}",
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
      path = "openssl-build.sh",
    },
  }
  in

  let openssl = {
    version | default = "3.5.7",
    name = "openssl-%{version}",
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
      source = openssl_src version,
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
