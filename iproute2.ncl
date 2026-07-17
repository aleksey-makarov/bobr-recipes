let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iproute2_src = fun version =>
    fun hash =>
    {
      name = "iproute2-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-%{version}.tar.xz",
      },
    }
  in

  let iproute2 = {
    version | default = "7.1.0",
    source_object_hash | default = "fd9fa1b95809417157ca83dd72957e3261bdbce896353cb936f80af0b33a4b5c",
    name = "iproute2-%{version}",
    tag = "MakefileInstall",
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
          "install -vDm644 COPYING README* -t \"/usr/share/doc/iproute2-%{version}\"",
        ],
      },
    },
    inputs = {
      source = iproute2_src version source_object_hash,
    },
  }
  in

  {
    include [
      iproute2,
    ],
  }
