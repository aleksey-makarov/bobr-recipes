let recipe = import "recipe-lib.ncl" in
let hashes = {
  "9.1.1629" = "26169f05b9b8fba0aa69ae18d342fcffbe9a8512db287d1cb975112e9879e952",
  "9.2.0680" = "51947928a257debaf2f969a469b9005a5a3eb438a0d737d767d2ce3f9fd66acc",
}
in
let runtime_dirs = {
  "9.1.1629" = "vim91",
  "9.2.0680" = "vim92",
}
in

fun pkgs =>
  let vim_src = fun version =>
    {
      name = "vim-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
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
    runtime_dir = runtime_dirs."%{version}",
    name = "vim-%{version}",
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
            mkdir -p "@{out}/usr/bin"
            mkdir -p "@{out}/usr/share/doc"
            mkdir -p "@{out}/etc"
            ln -svf vim "@{out}/usr/bin/vi"
            for L in "@{out}"/usr/share/man/{,*/}man1/vim.1; do
              if [ -e "$L" ]; then
                ln -svf vim.1 "$(dirname "$L")/vi.1"
              fi
            done
            ln -svf ../vim/%{runtime_dir}/doc "@{out}/usr/share/doc/vim-%{version}"
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
      source = vim_src version,
    },
  }
  in

  {
    include [
      vim,
    ],
  }
