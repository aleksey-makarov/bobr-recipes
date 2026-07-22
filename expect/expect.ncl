fun pkgs =>
  let expect_src = fun version => fun hash => {
    name = "expect-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/expect/Expect/%{version}/expect%{version}.tar.gz",
        "https://sourceforge.net/projects/expect/files/Expect/%{version}/expect%{version}.tar.gz/download",
      ],
    },
  }
  in

  let expect_gcc15_patch = {
    name = "expect-gcc15-patch",
    tag = "Source",
    object_hash = import "expect-5.45.4-gcc15-1.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "expect/expect-5.45.4-gcc15-1.patch",
    },
  }
  in

  let expect = {
    version | default = "5.45.4",
    source_object_hash | default = "49a7da83b0bdd9f46d04a04deec19c7767bb9a323e40c4781f89caf760b92c34",
    name = "expect-%{version}",
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
          "expect%{version}/libexpect%{version}.so",
          "/usr/lib/libexpect%{version}.so",
        ],
      },
    },
    inputs = {
      source = expect_src version source_object_hash,
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
