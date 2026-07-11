let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expat_src = fun version =>
    fun hash =>
    let release_tag = "R_2_8_2" in
    {
      name = "expat-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://github.com/libexpat/libexpat/releases/download/%{release_tag}/expat-%{version}.tar.xz",
      },
    }
  in

  let expat = {
    version | default = "2.8.2",
    source_object_hash | default = "3ad89b8588e6644bd4e49981480d48b21289eebbcd4f0a1a4afb1c29f99b6ab4",
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
      source = expat_src version source_object_hash,
    },
  }
  in

  {
    include [
      expat,
    ],
  }
