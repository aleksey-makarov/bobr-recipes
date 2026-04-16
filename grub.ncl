let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in
  let grub_src =
    recipe.fetch "grub-src-2.12" {
      url = [
        "https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grub/grub-2.12.tar.xz",
      ],
      hash = "md5:60c564b1bdc39d8e43b3aab4bc0fb140",
    }
  in

  let grub =
    build.build_autotools {
      name = "grub-2.12",
      sources = [grub_src],
      script_config = {
        pre_configure = m%"
          unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
          echo 'depends bli part_gpt' > grub-core/extra_deps.lst
        "%,
        configure_args = [
          "--sysconfdir=/etc",
          "--disable-efiemu",
          "--disable-werror",
        ],
        post_install = m%"
          install -vdm755 ${MBUILD_INSTALL_DIR}/usr/share/bash-completion/completions
          if [ -f ${MBUILD_INSTALL_DIR}/etc/bash_completion.d/grub ]; then
            mv -v ${MBUILD_INSTALL_DIR}/etc/bash_completion.d/grub \
                  ${MBUILD_INSTALL_DIR}/usr/share/bash-completion/completions/grub
            rmdir -p --ignore-fail-on-non-empty ${MBUILD_INSTALL_DIR}/etc/bash_completion.d 2>/dev/null || true
          fi
        "%,
      },
    }
  in

  {
    include [
      grub_src,
      grub,
    ],
  }
