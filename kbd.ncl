let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kbd_src =
    recipe.fetch "kbd-src-2.8.0" {
      url = "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.8.0.tar.xz",
      hash = "md5:24b5d24f7483726b88f214dc6c77aa41",
    }
  in

  let kbd_backspace_patch =
    recipe.fetch "kbd-backspace-patch" {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/kbd-2.8.0-backspace-1.patch",
      hash = "md5:f75cca16a38da6caa7d52151f7136895",
      unpack = false,
    }
  in

  let kbd =
    let script_config = {
        pre_configure = m%"
          patch -Np1 -i /in/sources1
          sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
          sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
        "%,
        configure_args = [
          "--disable-vlock",
        ],
        post_install = m%"
          install -vdm755 ${MBUILD_INSTALL_DIR}/usr/share/doc
          cp -R -v ${MBUILD_SOURCE_DIR}/docs/doc -T ${MBUILD_INSTALL_DIR}/usr/share/doc/kbd-2.8.0
        "%,
      }
    in
    recipe.binary "kbd-2.8.0" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_autotools [kbd_src, kbd_backspace_patch]
  in

  {
    include [
      kbd_src,
      kbd_backspace_patch,
      kbd,
    ],
  }
