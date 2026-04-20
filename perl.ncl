let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let buildscript_perl_configure =
    {
      name = "buildscript-perl-configure",
      tag = "Text",
      config = {
      executable = true,
      source = import "perl-configure.sh" as 'Text,
      },
      inputs = {},
    }
  in

  let perl_src =
    {
      name = "perl-src-5.42.0",
      tag = "Fetch",
      config = {
      url = "https://www.cpan.org/src/5.0/perl-5.42.0.tar.xz",
      hash = "md5:7a6950a9f12d01eb96a9d2ed2f4e0072",
      },
      inputs = {},
    }
  in

  let perl_build_image =
    {
      name = "perl-build-image",
      tag = "Image",
      config = { ref_name | default = "perl-build-image" } & {},
      inputs = {
        base = pkgs.system_image_2,
        inputs = [
      pkgs.zlib,
      pkgs.bzip2,
      pkgs.less,
    ],
      },
    }
  in

  let perl =
    recipe.binary "perl-5.42.0" {} perl_build_image buildscript_perl_configure [perl_src]
  in

  {
    include [
      perl_src,
      perl,
    ],
  }
