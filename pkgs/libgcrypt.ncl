# libgcrypt -- the GnuPG general-purpose crypto library. gcr (linked by
# gnome-shell) needs it. Plain Autotools; finds libgpg-error via its
# gpg-error-config in the build rootfs. Ships libgcrypt-config (meson consumers
# such as gcr locate it through that config tool, so no .pc is required).
# Configure version and hash through `pkgs.libgcrypt_src`.
fun pkgs =>
  let libgcrypt_src = {
    version | default = "1.12.2",
    name = "libgcrypt-src-%{version}",
    tag = "Source",
    object_hash | default = "7ce33c2492221a0436f96a8500215e9f3e3dcb5fd26a757cd415e7a843babd5e",
    origin = {
      tag = "Http",
      url = "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-%{version}.tar.bz2",
    },
  }
  in

  let libgcrypt = {
    name = "libgcrypt-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libgpg_error,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libgcrypt_src,
    },
  }
  in

  {
    include [
      libgcrypt_src,
      libgcrypt,
    ],
  }
