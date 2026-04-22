let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let buildscript_perl_configure = {
    name = "buildscript-perl-configure",
    tag = "Text",
    config = {
      executable = true,
      source = import "perl-configure.sh" as 'Text,
    },
    inputs = {},
  }
  in

  let perl_src = {
    name = "perl-src-5.42.0",
    tag = "Fetch",
    config = {
      url = "https://www.cpan.org/src/5.0/perl-5.42.0.tar.xz",
      hash = "md5:7a6950a9f12d01eb96a9d2ed2f4e0072",
    },
    inputs = {},
  }
  in

  let perl_build_image = {
    name = "perl-build-image",
    tag = "Image",
    config = { ref_name | default = "perl-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.zlib,
        pkgs.bzip2,
        pkgs.less,
      ],
  }
  in

  let perl = {
    name = "perl-5.42.0",
    tag = "Binary",
    config = {
      steps = [
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "configure"],
          env = { MBUILD_SOURCE_DIR = "@{source}" },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "build"],
          env = { MBUILD_SOURCE_DIR = "@{source}" },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "install"],
          env = { MBUILD_SOURCE_DIR = "@{source}" },
        },
      ],
    },
    inputs = {
      image = perl_build_image,
      script = buildscript_perl_configure,
      source = perl_src,
    },
  }
  in

  {
    include [
      perl_src,
      perl,
    ],
  }
