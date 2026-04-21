let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gawk_src = {
    name = "gawk-src-5.3.2",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-5.3.2.tar.xz",
      ],
      hash = "md5:b7014650c5f45e5d4837c31209dc0037",
    },
    inputs = {},
  }
  in

  let gawk_gen1 =
    recipe.autotools.binary
      "gawk-gen1-5.3.2"
      {
        step_transform =
          recipe.steps.insert_before_step
            "configure"
            [
              recipe.steps.step
                "prepare_source"
                "build-user"
                "${in1}"
                [
                  "/bin/sh",
                  "-ec",
                  "sed -i 's/extras//' Makefile.in",
                ],
            ],
        script_config = {
          configure_args = ["--without-readline"],
        },
      }
      pkgs.host_image
      [gawk_src]
  in

  let gawk =
    recipe.binary
      "gawk-5.3.2"
      {
        script_config = {
          pre_configure = "sed -i 's/extras//' Makefile.in",
          configure_args = ["--without-readline"],
        },
      }
      pkgs.system_image_1
      pkgs.buildscript_autotools
      [gawk_src]
  in

  {
    include [
      gawk_src,
      gawk_gen1,
      gawk,
    ],
  }
