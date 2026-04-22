let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xml_parser_src = {
    name = "xml-parser-src-2.47",
    tag = "Fetch",
    config = {
      url = "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz",
      hash = "md5:89a8e82cfd2ad948b349c0a69c494463",
    },
    inputs = {},
  }
  in

  let xml_parser = {
    name = "xml-parser-2.47",
    tag = "PerlModule",
    config = {},
    inputs = {
      image = pkgs.system_image,
      source = xml_parser_src,
    },
  }
  in

  {
    include [
      xml_parser_src,
      xml_parser,
    ],
  }
