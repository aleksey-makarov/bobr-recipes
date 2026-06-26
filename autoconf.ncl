let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.72" = "b3e588c79a56d7cb5f8dce6bf383ec1c01b4a85ef5700ef967ad08de7cbfc8ab",
  "2.73" = "cb8c3d26e2faecb5ddf70e8cf44c4857467a848339dd535669a6367dae9b52fb",
} in

fun pkgs =>
  let autoconf_src = fun version => {
    name = "autoconf-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/autoconf/autoconf-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/autoconf/autoconf-%{version}.tar.xz",
      ],
    },
  }
  in

  let autoconf_build_rootfs = {
    name = "autoconf-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.perl,
        pkgs.inetutils,
      ],
  }
  in

  let autoconf = {
    version | default = "2.73",
    name = "autoconf-%{version}",
    tag = "AutotoolsRootfs",
    config = {},
    inputs = {
      rootfs = autoconf_build_rootfs,
      source = autoconf_src version,
    },
  }
  in

  {
    include [
      autoconf,
    ],
  }
