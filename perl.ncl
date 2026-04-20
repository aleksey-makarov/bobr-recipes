let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let buildscript_perl_configure =
    recipe.text "buildscript-perl-configure" {
      executable = true,
      source = import "perl-configure.sh" as 'Text,
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
    recipe.image "perl-build-image" {} pkgs.system_image_2 [
      pkgs.zlib,
      pkgs.bzip2,
      pkgs.less,
    ]
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
