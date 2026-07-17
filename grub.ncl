let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grub_src = fun version => fun hash => {
    name = "grub-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/grub/grub-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/grub/grub-%{version}.tar.xz",
      ],
    },
  }
  in

  let grub = {
    version | default = "2.12",
    source_object_hash | default = "f3c97391f7c4eaa677a78e090c7e97e6dc47b16f655f04683ebd37bef7fe0faa",
    name = "grub-%{version}",
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
            install -vdm755 "/usr/share/bash-completion/completions"
            if [ -f "/etc/bash_completion.d/grub" ]; then
              mv -v "/etc/bash_completion.d/grub" \
                    "/usr/share/bash-completion/completions/grub"
              rmdir -p --ignore-fail-on-non-empty "/etc/bash_completion.d" 2>/dev/null || true
            fi
          "%,
        ],
      },
    },
    inputs = {
      source = grub_src version source_object_hash,
    },
  }
  in

  {
    include [
      grub,
    ],
  }
