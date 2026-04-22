let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grub_src = {
    name = "grub-src-2.12",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grub/grub-2.12.tar.xz",
      ],
      hash = "md5:60c564b1bdc39d8e43b3aab4bc0fb140",
    },
    inputs = {},
  }
  in

  let grub = {
    name = "grub-2.12",
    tag = "Autotools",
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
            install -vdm755 "${out}/usr/share/bash-completion/completions"
            if [ -f "${out}/etc/bash_completion.d/grub" ]; then
              mv -v "${out}/etc/bash_completion.d/grub" \
                    "${out}/usr/share/bash-completion/completions/grub"
              rmdir -p --ignore-fail-on-non-empty "${out}/etc/bash_completion.d" 2>/dev/null || true
            fi
          "%,
        ],
      },
    },
    inputs = {
      image = pkgs.system_image,
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
