let recipe = import "../../recipe-lib.ncl" in

fun pkgs =>
  let slang_src = fun version =>
    fun hash =>
      {
        name = "slang-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.jedsoft.org/releases/slang/slang-%{version}.tar.bz2",
        },
      }
  in

  let use_path_ln_patch = {
    name = "slang-use-path-ln-patch",
    tag = "Source",
    object_hash = import "slang-2.3.3-use-path-ln.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/slang/slang-2.3.3-use-path-ln.patch",
    },
  }
  in

  let slang = {
    version | default = "2.3.3",
    source_object_hash | default = "f9145054ae131973c61208ea82486d5dd10e3c5cdad23b7c4a0617743c8f5a18",
    name = "slang-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libpng,
        pkgs.ncurses,
        pkgs.zlib,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.libpng,
        pkgs.ncurses_libs,
        pkgs.zlib,
      ],
    },
    config = {
      in-tree = true,
      configure_args = [
        "--without-pcre",
        "--without-x",
        "--with-png=/usr",
        "--with-zlib=/usr/lib64",
        "--with-zinc=/usr/include",
        "--with-readline=slang",
        "--with-pkgconfigdir=/usr/lib/pkgconfig",
      ],
      # S-Lang reads terminfo itself, but consumers expect its pkg-config
      # metadata to carry the curses dependency, as in the major distros.
      post_install = {
        name = "link_slang_consumers_with_ncurses",
        run_as = "root",
        argv = [
          "sed",
          "-i",
          "/^Libs:/s/$/ -lncurses/",
          "/usr/lib/pkgconfig/slang.pc",
        ],
      },
    },
    inputs = {
      source = slang_src version source_object_hash,
      patch_use_path_ln = use_path_ln_patch,
    },
  }
  in

  let slang_libs =
    recipe.split.libs slang "usr/lib/libslang.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      use_path_ln_patch,
      slang,
      slang_libs,
    ],
  }
