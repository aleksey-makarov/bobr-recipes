let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xml_parser_src = {
    name = "xml-parser-src-2.47",
    tag = "Source",
    object_hash = "961203edf594304f0b6c5b547c7bf7fd0b8a7c6a2fd3647e79b837dcb912d6dc",
    origin = {
      type = "http",
      url = "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz",
      unpack = true,
    },
    meta = {},
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
