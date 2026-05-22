let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grub_src = {
    name = "grub-src-2.12",
    tag = "Source",
    object_hash = "d665fdc6e3c5432995783be9f16ce22b1f6363422ee2f85b902d7bc06ebf4119",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grub/grub-2.12.tar.xz",
      ],
    },
  }
  in

  let grub = {
    name = "grub-2.12",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.bison,
        pkgs.flex,
        pkgs.python,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.xz_libs,
      ],
    },
    config = {
      pre_configure = {
        name = "prepare_grub_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
            echo 'depends bli part_gpt' > grub-core/extra_deps.lst
          "%,
        ],
      },
      configure_args = [
        "--sysconfdir=/etc",
        "--sbindir=/usr/bin",
        "--disable-efiemu",
        "--disable-werror",
      ],
      post_install = {
        name = "move_grub_bash_completion",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            install -vdm755 "@{out}/usr/share/bash-completion/completions"
            if [ -f "@{out}/etc/bash_completion.d/grub" ]; then
              mv -v "@{out}/etc/bash_completion.d/grub" \
                    "@{out}/usr/share/bash-completion/completions/grub"
              rmdir -p --ignore-fail-on-non-empty "@{out}/etc/bash_completion.d" 2>/dev/null || true
            fi
          "%,
        ],
      },
    },
    inputs = {
      source = grub_src,
    },
  }
  in

  {
    include [
      grub_src,
      grub,
    ],
  }
