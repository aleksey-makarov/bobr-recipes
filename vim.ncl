let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let vim_src = fun version =>
    fun hash =>
    {
      name = "vim-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = [
          "https://github.com/vim/vim/archive/v%{version}/vim-%{version}.tar.gz",
        ],
      },
    }
  in

  let vim = {
    version | default = "9.2.0680",
    source_object_hash | default = "9f306d8a25fc688ad2b814c1c420833ed20ff86deca907a81db0af08dde51a6f",
    runtime_dir = "vim92",
    name = "vim-%{version}",
    tag = "AutotoolsInstall",
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
      # Pin the recorded builder; otherwise vim's pathdef.c derives compiled_user
      # from (logname || whoami). logname reads /proc/self/loginuid, which the
      # namespace runtime translates to uid 0 (-> "root") while the host runtime
      # leaves it unresolved (-> empty), making the binary non-reproducible.
      configure_args = ["--with-compiledby=bobr"],
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
            mkdir -p "/usr/bin"
            mkdir -p "/usr/share/doc"
            mkdir -p "/etc"
            ln -svf vim "/usr/bin/vi"
            for L in /usr/share/man/{,*/}man1/vim.1; do
              if [ -e "$L" ]; then
                ln -svf vim.1 "$(dirname "$L")/vi.1"
              fi
            done
            ln -svf ../vim/%{runtime_dir}/doc "/usr/share/doc/vim-%{version}"
            cat > "/etc/vimrc" <<'EOF_INNER'
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
      source = vim_src version source_object_hash,
    },
  }
  in

  {
    include [
      vim,
    ],
  }
