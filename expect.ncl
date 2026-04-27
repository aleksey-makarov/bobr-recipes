let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expect_src = {
    name = "expect-src-5.45.4",
    tag = "Source",
    object_hash = "1b04d81daae40a60d9df051fa6c006bf51a5ecd62f0bad01452f60a377c59330",
    origin = {
      type = "http",
      url = [
        "https://downloads.sourceforge.net/project/expect/Expect/5.45.4/expect5.45.4.tar.gz",
        "https://sourceforge.net/projects/expect/files/Expect/5.45.4/expect5.45.4.tar.gz/download",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let expect_gcc15_patch = {
    name = "expect-gcc15-patch",
    tag = "Source",
    object_hash = "52526d260124716c3d0d922ab3b5bfc43cc1ac82d473151e837ec852ab8b0e9f",
    origin = {
      type = "http",
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/expect-5.45.4-gcc15-1.patch",
      unpack = false,
    },
    meta = {},
  }
  in

  let expect_build_image = {
    name = "expect-build-image",
    tag = "Image",
    config = { ref_name | default = "expect-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.tcl,
      ],
  }
  in

  let expect = {
    name = "expect-5.45.4",
    tag = "Autotools",
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
      image = expect_build_image,
      source = expect_src,
      gcc15_patch = expect_gcc15_patch,
    },
  }
  in

  {
    include [
      expect_src,
      expect_gcc15_patch,
      expect,
    ],
  }
