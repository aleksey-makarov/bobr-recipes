let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expect_src =
    recipe.fetch "expect-src-5.45.4" {
      url = [
        "https://downloads.sourceforge.net/project/expect/Expect/5.45.4/expect5.45.4.tar.gz",
        "https://sourceforge.net/projects/expect/files/Expect/5.45.4/expect5.45.4.tar.gz/download",
      ],
      hash = "md5:00fce8de158422f5ccd2666512329bd2",
    }
  in

  let expect_gcc15_patch =
    recipe.fetch "expect-gcc15-patch" {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/expect-5.45.4-gcc15-1.patch",
      hash = "md5:0ca4d6bb8d572fbcdb13cb36cd34833e",
      unpack = false,
    }
  in

  let expect_build_image =
    recipe.image "expect-build-image" {} pkgs.system_image [
      pkgs.tcl,
    ]
  in

  let expect =
    recipe.binary "expect-5.45.4" {
      script_config = {
        pre_configure = "patch -Np1 -i /in/sources1",
        configure_args = [
          "--with-tcl=/usr/lib",
          "--enable-shared",
          "--disable-rpath",
          "--mandir=/usr/share/man",
          "--with-tclinclude=/usr/include",
        ],
        post_install = "ln -sfv expect5.45.4/libexpect5.45.4.so /out/${out}/usr/lib/libexpect5.45.4.so",
      },
    } expect_build_image pkgs.buildscript_autotools [expect_src, expect_gcc15_patch]
  in

  {
    include [
      expect_src,
      expect_gcc15_patch,
      expect,
    ],
  }
