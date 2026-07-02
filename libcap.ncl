let recipe = import "recipe-lib.ncl" in
let hashes = {
  "2.76" = "0b4ab42297fcc500b2f6bf7e84541f5efbe5bb2160343733bd153cb8ecbca4c5",
  "2.78" = "6db52bfba9d8b05756c369b7befa2b94d857e295d083b3423ec74bbfb8266e04",
} in

fun pkgs =>
  let libcap_src = fun version => {
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
