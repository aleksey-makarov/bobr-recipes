let recipe = import "../recipe-lib.ncl" in
# Perl and its build-only CPAN modules are aggregated here so pkgs.ncl imports
# only perl/perl.ncl (not each module file individually).
let mk_perl_parse_yapp = import "perl-parse-yapp.ncl" in
let mk_perl_xml_parser = import "perl-xml-parser.ncl" in

fun pkgs =>
  let buildscript_perl_configure = {
    name = "buildscript-perl-configure",
    tag = "Source",
    object_hash = import "perl-configure.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "perl/perl-configure.sh",
    },
  }
  in

  let perl_src = fun version =>
    fun hash =>
      {
        name = "perl-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.cpan.org/src/5.0/perl-%{version}.tar.xz",
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
      ],
  }
  in

  let perl = {
    version | default = "5.42.2",
    source_object_hash | default = "0a585eeb9e363c0f80482ddb3571625250c2c86aeb408853e8ea50805cfb14bb",
    name = "perl-%{version}",
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
          env = { BOBR_SOURCE_DIR = "@{build}/source" },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "build"],
          env = { BOBR_SOURCE_DIR = "@{build}/source" },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "install"],
          env = { BOBR_SOURCE_DIR = "@{build}/source" },
        },
      ],
    },
    inputs = {
      _rootfs = perl_build_rootfs,
      script = buildscript_perl_configure,
      source = perl_src version source_object_hash,
    },
  }
  in

  # `include` names each field after the identifier, so bind the applied nodes
  # to their attribute names first (it cannot take an application expression).
  let perl_parse_yapp = mk_perl_parse_yapp pkgs in
  let perl_xml_parser = mk_perl_xml_parser pkgs in
  { include [perl, perl_parse_yapp, perl_xml_parser] }
