let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let vim_src =
    recipe.fetch "vim-src-9.1.1629" {
      url = [
        "https://github.com/vim/vim/archive/v9.1.1629/vim-9.1.1629.tar.gz",
      ],
      hash = "md5:4f856c3233c1c4570bc17572e4f9e8e4",
    }
  in

  let vim =
    build.build_autotools {
      name = "vim-9.1.1629",
      sources = [vim_src],
      script_config = {
        pre_configure = "echo '#define SYS_VIMRC_FILE \"/etc/vimrc\"' >> src/feature.h",
        configure_args = [],
        post_install = m%"
          mkdir -p "/out/${out}/usr/bin"
          mkdir -p "/out/${out}/usr/share/doc"
          mkdir -p "/out/${out}/etc"
          ln -svf vim "/out/${out}/usr/bin/vi"
          for L in /out/${out}/usr/share/man/{,*/}man1/vim.1; do
            if [ -e "$L" ]; then
              ln -svf vim.1 "$(dirname "$L")/vi.1"
            fi
          done
          ln -svf ../vim/vim91/doc "/out/${out}/usr/share/doc/vim-9.1.1629"
          cat > "/out/${out}/etc/vimrc" <<'EOF_INNER'
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
      },
    }
  in

  {
    include [
      vim_src,
      vim,
    ],
  }
