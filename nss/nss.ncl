# NSS -- Network Security Services (Mozilla). evolution-data-server's camel
# links libnss3/libssl3/libsmime3 unconditionally (certificate database + TLS),
# so NSS is a hard eds dependency. NSS has no configure/`make install`; it builds
# with its own coreconf make system and installs by hand (see nss-build.sh). The
# build rootfs is the native toolchain closure plus NSPR, system sqlite, zlib,
# perl and python. `version`/`source_object_hash` are node fields (overridable).
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_nss = {
    name = "buildscript-nss",
    tag = "Source",
    object_hash = import "nss-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "nss/nss-build.sh",
    },
  }
  in

  let nss_src = fun version =>
    fun hash =>
      let rtm_tag = std.string.replace "." "_" version in
      {
        name = "nss-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://ftp.mozilla.org/pub/security/nss/releases/NSS_%{rtm_tag}_RTM/src/nss-%{version}.tar.gz",
        },
      }
  in

  let nss_build_rootfs =
    recipe.native_build_rootfs pkgs "nss-build-rootfs" [
      pkgs.nspr,
      pkgs.sqlite,
      pkgs.zlib,
      pkgs.perl,
      pkgs.python,
    ]
  in

  let step_env = { BOBR_SOURCE_DIR = "@{build}/source" } in

  let nss = {
    version | default = "3.125",
    source_object_hash
      | default
      = "1ad541f10da7c58dec01f540ecc44d28cbbc033f741a57473de5a0893d91606d",
    name = "nss-%{version}",
    tag = "SandboxBuildRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.nspr,
        pkgs.sqlite,
        pkgs.zlib,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "build"],
          env = step_env,
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "install"],
          env = step_env,
        },
      ],
    },
    inputs = {
      _rootfs = nss_build_rootfs,
      script = buildscript_nss,
      source = nss_src version source_object_hash,
    },
  }
  in

  {
    include [
      nss,
    ],
  }
