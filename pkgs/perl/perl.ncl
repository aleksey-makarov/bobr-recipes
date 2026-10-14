let recipe = import "../../recipe-lib.ncl" in
let br = import "../../build-rootfs.ncl" in
# Perl and its build-only CPAN modules are aggregated here so the package set
# imports only perl/perl.ncl (not each module file individually).
fun pkgs =>
  let buildscript_perl_configure = {
    name = "buildscript-perl-configure",
    tag = "Source",
    object_hash = import "perl-configure.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/perl/perl-configure.sh",
    },
  }
  in

  let perl_src = {
    version | default = "5.42.2",
    name = "perl-src-%{version}",
    tag = "Source",
    object_hash | default = "0a585eeb9e363c0f80482ddb3571625250c2c86aeb408853e8ea50805cfb14bb",
    origin = {
      tag = "Http",
      url = "https://www.cpan.org/src/5.0/perl-%{version}.tar.xz",
    },
  }
  in

  let perl = {
    name = "perl-%{inputs.source.version}",
    tag = "SandboxStageDeps",
    deps = {
      # Deps-derived build rootfs (SandboxStageDeps assembles it, no hand-rolled
      # _rootfs), replacing the curated system_rootfs_2: the native toolchain
      # (already includes bzip2/xz) plus zlib, which perl's Compress::Zlib links.
      # perl is a default Autotools build dep but not a native-toolchain member,
      # so this closure does not pull perl back in.
      build = br.native_build_deps pkgs @ [pkgs.zlib],
      runtime = [
        pkgs.c_runtime,
        pkgs.bzip2,
        pkgs.zlib,
      ],
    },
    config =
      let step_env = {
        BOBR_SOURCE_DIR = "@{build}/source",
        PERL_API_VERSION = recipe.version_prefix 2 inputs.source.version,
      }
      in
      {
        steps = [
          recipe.prepare_source_step,
          {
            name = "configure",
            run_as = "build-user",
            cwd = "@{build}",
            argv = ["@{script}", "configure"],
            env = step_env,
          },
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
      script = buildscript_perl_configure,
      source = pkgs.perl_src,
    },
  }
  in

  { include [perl_src, perl] }
  & (import "perl-parse-yapp.ncl") pkgs
  & (import "perl-xml-parser.ncl") pkgs
