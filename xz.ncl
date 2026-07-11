let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xz_src = fun version => fun hash => {
    name = "xz-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/tukaani-project/xz/releases/download/v%{version}/xz-%{version}.tar.xz",
    },
  }
  in

  let xz_gen1 = {
    version | default = "5.8.1",
    source_object_hash | default = "0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e",
    name = "xz-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/xz-%{version}",
      ],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = xz_src version source_object_hash,
    },
  }
  in

  let xz = {
    version | default = "5.8.1",
    source_object_hash | default = "0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e",
    name = "xz-%{version}",
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
        "--docdir=/usr/share/doc/xz-%{version}",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = xz_src version source_object_hash,
    },
  }
  in

  let xz_libs =
    recipe.split.libs xz "usr/lib/liblzma.so*"
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
      xz_gen1,
      xz,
      xz_libs,
    ],
  }
