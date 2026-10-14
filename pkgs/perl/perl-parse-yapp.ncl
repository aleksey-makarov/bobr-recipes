# Parse::Yapp -- Perl LALR parser generator. Samba's PIDL (the IDL compiler that
# generates its DCE/RPC stubs) requires the Parse::Yapp::Driver module at build
# time. Build-only Perl module.
fun pkgs =>
  let perl_parse_yapp_src = {
    version | default = "1.21",
    name = "perl-parse-yapp-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "3810e998308fba2e0f4f26043035032b027ce51ce5c8a52a8b8e340ca65f13e5",
    origin = {
      tag = "Http",
      url = "https://cpan.metacpan.org/authors/id/W/WB/WBRASWELL/Parse-Yapp-%{version}.tar.gz",
    },
  }
  in

  let perl_parse_yapp = {
    name = "perl-parse-yapp-%{inputs.source.version}",
    tag = "PerlModule",
    deps = {
      build = [],
      runtime = [
        pkgs.perl,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.perl_parse_yapp_src,
    },
  }
  in

  { include [perl_parse_yapp_src, perl_parse_yapp] }
