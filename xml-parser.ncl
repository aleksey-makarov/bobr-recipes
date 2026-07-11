let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xml_parser_src = fun version => fun hash => {
    name = "xml-parser-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-%{version}.tar.gz",
    },
  }
  in

  let xml_parser = {
    version | default = "2.47",
    source_object_hash | default = "ad4aae643ec784f489b956abe952432871a622d4e2b5c619e8855accbfc4d1d8",
    name = "xml-parser-%{version}",
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
      source = xml_parser_src version source_object_hash,
    },
  }
  in

  {
    include [
      xml_parser,
    ],
  }
