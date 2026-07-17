# libgcrypt -- the GnuPG general-purpose crypto library. gcr (linked by
# gnome-shell) needs it. Plain Autotools; finds libgpg-error via its
# gpg-error-config in the build rootfs. Ships libgcrypt-config (meson consumers
# such as gcr locate it through that config tool, so no .pc is required).
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libgcrypt_src = fun version =>
    fun hash =>
      {
        name = "libgcrypt-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-%{version}.tar.bz2",
        },
      }
  in

  let libgcrypt = {
    version | default = "1.12.2",
    source_object_hash
      | default
      = "7ce33c2492221a0436f96a8500215e9f3e3dcb5fd26a757cd415e7a843babd5e",
    name = "libgcrypt-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.libgpg_error,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.libgpg_error,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-doc",
      ],
    },
    inputs = {
      source = libgcrypt_src version source_object_hash,
    },
  }
  in

  {
    include [
      libgcrypt,
    ],
  }
