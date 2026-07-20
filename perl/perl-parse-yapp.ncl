# Parse::Yapp -- Perl LALR parser generator. Samba's PIDL (the IDL compiler that
# generates its DCE/RPC stubs) requires the Parse::Yapp::Driver module at build
# time. Build-only Perl module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let perl_parse_yapp_src = fun version =>
    fun hash =>
      {
        name = "perl-parse-yapp-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://cpan.metacpan.org/authors/id/W/WB/WBRASWELL/Parse-Yapp-%{version}.tar.gz",
        },
      }
  in

  {
    version | default = "1.21",
    source_object_hash
      | default
      = "3810e998308fba2e0f4f26043035032b027ce51ce5c8a52a8b8e340ca65f13e5",
    name = "perl-parse-yapp-%{version}",
    tag = "PerlModule",
    deps = {
      build = [],
      runtime = [
        pkgs.perl,
      ],
    },
    config = {},
    inputs = {
      source = perl_parse_yapp_src version source_object_hash,
    },
  }
