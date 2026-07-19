let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let autoconf_src = fun version =>
    fun hash =>
    {
      name = "autoconf-src-%{version}",
      tag = "Source",
      object_hash = hash,
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
      ],
  }
  in

  let autoconf = {
    version | default = "2.73",
    source_object_hash | default = "9fd672b1c8425fac2fa67fa0477b990987268b90ff36d5f016dae57be0d6b52e",
    name = "autoconf-%{version}",
    tag = "AutotoolsRootfs",
    config = {},
    inputs = {
      _rootfs = autoconf_build_rootfs,
      source = autoconf_src version source_object_hash,
    },
  }
  in

  {
    include [
      autoconf,
    ],
  }
