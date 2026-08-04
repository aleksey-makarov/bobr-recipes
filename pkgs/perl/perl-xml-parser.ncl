# XML::Parser -- Perl wrapper around expat. intltool needs it at build time.
# Build-only Perl module with a native expat dependency.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let perl_xml_parser_src = fun version =>
    fun hash =>
      {
        name = "perl-xml-parser-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-%{version}.tar.gz",
        },
      }
  in

  {
    version | default = "2.47",
    source_object_hash | default = "ad4aae643ec784f489b956abe952432871a622d4e2b5c619e8855accbfc4d1d8",
    name = "perl-xml-parser-%{version}",
    tag = "PerlModule",
    deps = {
      build = [
        pkgs.expat,
      ],
      runtime = [
        pkgs.perl,
        pkgs.expat,
      ],
    },
    config = {},
    inputs = {
      source = perl_xml_parser_src version source_object_hash,
    },
  }
