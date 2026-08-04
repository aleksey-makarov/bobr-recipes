fun pkgs =>
  let texinfo_src = fun version => fun hash => {
    name = "texinfo-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/texinfo/texinfo-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/texinfo/texinfo-%{version}.tar.xz",
      ],
    },
  }
  in

  let texinfo = {
    version | default = "7.2",
    source_object_hash | default = "0329d7788fbef113fa82cb80889ca197a344ce0df7646fe000974c5d714363a6",
    name = "texinfo-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
        pkgs.perl,
      ],
    },
    config = {
      pre_configure = {
        name = "patch_texinfo_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm",
        ],
      },
      post_install = [
        {
          name = "install_tex_support",
          run_as = "root",
          cwd = "@{build}/build",
          argv = [
            "/bin/sh",
            "-ec",
            "make TEXMF=/usr/share/texmf install-tex",
          ],
        },
        # Without DESTDIR the `make install` step runs install-info, which
        # creates the system-wide /usr/share/info/dir TOC. Packages must not
        # ship that derived index (each would clobber the others on merge);
        # drop the copy we just created -- it is an upper-only file, so the
        # layer stays additive.
        {
          name = "drop_info_dir",
          run_as = "root",
          argv = ["rm", "-fv", "/usr/share/info/dir"],
        },
      ],
    },
    inputs = {
      source = texinfo_src version source_object_hash,
    },
  }
  in

  {
    include [
      texinfo,
    ],
  }
