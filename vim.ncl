let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let vim_src = {
    name = "vim-src-9.1.1629",
    tag = "Source",
    object_hash = "26169f05b9b8fba0aa69ae18d342fcffbe9a8512db287d1cb975112e9879e952",
    origin = {
      type = "http",
      url = [
        "https://github.com/vim/vim/archive/v9.1.1629/vim-9.1.1629.tar.gz",
      ],
    },
  }
  in

  let vim = {
    name = "vim-9.1.1629",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
      ],
    },
    config = {
      "in-tree" = true,
      pre_configure = {
        name = "set_system_vimrc",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "echo '#define SYS_VIMRC_FILE \"/etc/vimrc\"' >> src/feature.h",
        ],
      },
      post_install = {
        name = "install_runtime_links",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            mkdir -p "@{out}/usr/bin"
            mkdir -p "@{out}/usr/share/doc"
            mkdir -p "@{out}/etc"
            ln -svf vim "@{out}/usr/bin/vi"
            for L in "@{out}"/usr/share/man/{,*/}man1/vim.1; do
              if [ -e "$L" ]; then
                ln -svf vim.1 "$(dirname "$L")/vi.1"
              fi
            done
            ln -svf ../vim/vim91/doc "@{out}/usr/share/doc/vim-9.1.1629"
            cat > "@{out}/etc/vimrc" <<'EOF_INNER'
            " Begin /etc/vimrc

            source $VIMRUNTIME/defaults.vim

            let skip_defaults_vim=1
            set nocompatible
            set backspace=2
            set mouse=
            syntax on
            if (&term =~ "xterm") || (&term =~ "putty")
              set background=dark
            endif

            " End /etc/vimrc
            EOF_INNER
          "%,
        ],
      },
    },
    inputs = {
      source = vim_src,
    },
  }
  in

  {
    include [
      vim_src,
      vim,
    ],
  }
