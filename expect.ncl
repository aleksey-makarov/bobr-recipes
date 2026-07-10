let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expect_src = {
    name = "expect-src-5.45.4",
    tag = "Source",
    object_hash = "49a7da83b0bdd9f46d04a04deec19c7767bb9a323e40c4781f89caf760b92c34",
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/expect/Expect/5.45.4/expect5.45.4.tar.gz",
        "https://sourceforge.net/projects/expect/files/Expect/5.45.4/expect5.45.4.tar.gz/download",
      ],
    },
  }
  in

  let expect_gcc15_patch = {
    name = "expect-gcc15-patch",
    tag = "Source",
    object_hash = "ab5fc0af9e2e0f80d7623c1a3a3dbeb1da3d8c9134276792199df401f9eb2cec",
    origin = {
      tag = "RecipePath",
      path = "expect-5.45.4-gcc15-1.patch",
    },
  }
  in

  let expect = {
    name = "expect-5.45.4",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.tcl,
        pkgs.zlib,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.tcl,
        pkgs.zlib,
      ],
    },
    config = {
      pre_configure = {
        name = "apply_gcc15_patch",
        run_as = "build-user",
        argv = [
          "patch",
          "-Np1",
          "-i",
          "@{gcc15_patch}",
        ],
      },
      configure_args = [
        "--with-tcl=/usr/lib",
        "--enable-shared",
        "--disable-rpath",
        "--mandir=/usr/share/man",
        "--with-tclinclude=/usr/include",
      ],
      post_install = {
        name = "link_libexpect",
        run_as = "root",
        argv = [
          "ln",
          "-sfv",
          "expect5.45.4/libexpect5.45.4.so",
          "@{out}/usr/lib/libexpect5.45.4.so",
        ],
      },
    },
    inputs = {
      source = expect_src,
      gcc15_patch = expect_gcc15_patch,
    },
  }
  in

  {
    include [
      expect_gcc15_patch,
      expect,
    ],
  }
