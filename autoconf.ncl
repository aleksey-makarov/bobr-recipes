let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.72" = "ba885c1319578d6c94d46e9b0dceb4014caafe2490e437a0dbca3f270a223f5a",
  "2.73" = "9fd672b1c8425fac2fa67fa0477b990987268b90ff36d5f016dae57be0d6b52e",
}
in

fun pkgs =>
  let autoconf_src = fun version =>
    {
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
      _rootfs = autoconf_build_rootfs,
      source = autoconf_src version,
    },
  }
  in

  {
    include [
      autoconf,
    ],
  }
