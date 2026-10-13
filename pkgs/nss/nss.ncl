# NSS -- Network Security Services (Mozilla). evolution-data-server's camel
# links libnss3/libssl3/libsmime3 unconditionally (certificate database + TLS),
# so NSS is a hard eds dependency. NSS has no configure/`make install`; it builds
# with its own coreconf make system and installs by hand (see nss-build.sh). The
# build rootfs is the native toolchain closure plus NSPR, system sqlite, zlib,
# perl and python. Configure version and hash through pkgs.nss_src.
let recipe = import "../../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_nss = {
    name = "buildscript-nss",
    tag = "Source",
    object_hash = import "nss-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/nss/nss-build.sh",
    },
  }
  in

  # Configure version and hash through pkgs.nss_src.
  let nss_src = {
    version | default = "3.125",
    name = "nss-src-%{version}",
    tag = "Source",
    object_hash | default = "1ad541f10da7c58dec01f540ecc44d28cbbc033f741a57473de5a0893d91606d",
    origin =
      let rtm_tag = std.string.replace "." "_" version in
      {
        tag = "Http",
        url = "https://ftp.mozilla.org/pub/security/nss/releases/NSS_%{rtm_tag}_RTM/src/nss-%{version}.tar.gz",
      },
  }
  in

  let step_env = { BOBR_SOURCE_DIR = "@{build}/source" } in

  let nss = {
    name = "nss-%{inputs.source.version}",
    # SandboxStageDeps, not a plain additive SandboxInstallDeps: the install
    # ends with `chown -R 0:0 ${out_dir}/usr`, which under a direct install into
    # / would recurse the live /usr and rewrite lower-layer file metadata (an
    # additive violation). Installing into the virgin /stage scopes both the
    # install and the recursive chown to nss's own files; the lowering's
    # TreeMove re-roots /stage -> /. The build rootfs is deps-derived (no
    # hand-rolled _rootfs).
    tag = "SandboxStageDeps",
    deps = {
      build =
        recipe.native_build_deps pkgs
        @ [
          pkgs.nspr,
          pkgs.sqlite,
          pkgs.zlib,
          pkgs.perl,
          pkgs.python,
        ],
      runtime = [
        pkgs.c_runtime,
        pkgs.nspr,
        pkgs.sqlite,
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
      script = buildscript_nss,
      source = pkgs.nss_src,
    },
  }
  in

  {
    include [
      nss,
      nss_src,
    ],
  }
