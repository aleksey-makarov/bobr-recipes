let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.7.1" = "354552544b8f99012e5062f7d570ec77f14b412a3ff5c7d8d0dae62c0d217c30",
  "2.8.2" = "3ad89b8588e6644bd4e49981480d48b21289eebbcd4f0a1a4afb1c29f99b6ab4",
}
in
let release_tags = {
  "2.7.1" = "R_2_7_1",
  "2.8.2" = "R_2_8_2",
}
in

fun pkgs =>
  let expat_src = fun version =>
    let release_tag = release_tags."%{version}" in
    {
      name = "expat-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://github.com/libexpat/libexpat/releases/download/%{release_tag}/expat-%{version}.tar.xz",
      },
    }
  in

  let expat = {
    version | default = "2.8.2",
    name = "expat-%{version}",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/expat-%{version}",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = expat_src version,
    },
  }
  in

  {
    include [
      expat,
    ],
  }
