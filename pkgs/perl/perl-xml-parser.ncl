# XML::Parser -- Perl wrapper around expat. intltool needs it at build time.
# Build-only Perl module with a native expat dependency.
fun pkgs =>
  let perl_xml_parser_src = {
    version | default = "2.47",
    name = "perl-xml-parser-src-%{version}",
    tag = "Source",
    object_hash | default = "ad4aae643ec784f489b956abe952432871a622d4e2b5c619e8855accbfc4d1d8",
    origin = {
      tag = "Http",
      url = "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-%{version}.tar.gz",
    },
  }
  in

  let perl_xml_parser = {
    name = "perl-xml-parser-%{inputs.source.version}",
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
      source = pkgs.perl_xml_parser_src,
    },
  }
  in

  { include [perl_xml_parser_src, perl_xml_parser] }
