let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.76" = "629da4ab29900d0f7fcc36227073743119925fd711c99a1689bbf5c9b40c8e6f",
  "2.78" = "0d621e562fd932ccf67b9660fb018e468a683d7b827541df27813228c996bb11",
}
in

fun pkgs =>
  let libcap_src = fun version =>
    {
      name = "libcap-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-%{version}.tar.xz",
      },
    }
  in

  let libcap = {
    version | default = "2.78",
    name = "libcap-%{version}",
    tag = "MakefileRootfs",
    config = {
      pre_build = {
        name = "drop_static_install_rule",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i '/install -m.*STA/d' libcap/Makefile",
        ],
      },
      make_args = [
        "prefix=/usr",
        "lib=lib",
        "sbin=bin",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = libcap_src version,
    },
  }
  in

  let libcap_libs =
    recipe.split.libs libcap "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      libcap,
      libcap_libs,
    ],
  }
