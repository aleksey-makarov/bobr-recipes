let recipe = import "recipe-lib.ncl" in
let hashes = {
  "6.16.0" = "5f574f0c0c90971c342eecf5751cd7cdb61494bef06aea53fd8ebc8f459bef18",
  "7.1.0" = "4981c01923100cabdf395030fc774ed1ef1e0163e1d7969bf9b0f4013ee41442",
} in

fun pkgs =>
  let iproute2_src = fun version => {
    name = "iproute2-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-%{version}.tar.xz",
    },
  }
  in

  let iproute2 = {
    version | default = "7.1.0",
    name = "iproute2-%{version}",
    tag = "Makefile",
    deps = {
      build = [
        pkgs.bison,
        pkgs.flex,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      pre_build = {
        name = "prepare_iproute2_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -i /ARPD/d Makefile
            rm -fv man/man8/arpd.8
          "%,
        ],
      },
      make_args = [
        "NETNS_RUN_DIR=/run/netns",
        "SBINDIR=/usr/bin",
      ],
      post_install = {
        name = "install_docs",
        run_as = "root",
        cwd = "@{build}/source",
        argv = [
          "/bin/sh",
          "-ec",
          "install -vDm644 COPYING README* -t \"@{out}/usr/share/doc/iproute2-%{version}\"",
        ],
      },
    },
    inputs = {
      source = iproute2_src version,
    },
  }
  in

  {
    include [
      iproute2,
    ],
  }
