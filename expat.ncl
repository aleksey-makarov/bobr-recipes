let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.7.1" = "abdbb1ff22e063a4fafeebf73a0f250ea166a52cd264d557ef25a13cc93cd9bf",
  "2.8.2" = "a5cc72bb064f8ac583ddc3f2e3dc6043b801b9d2162504c656fe8d92ffa85e46",
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
