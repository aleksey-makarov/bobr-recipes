let recipe = import "recipe-lib.ncl" in
let br = import "build-rootfs.ncl" in

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

  # Deps-derived build rootfs, replacing the curated system_rootfs_2. xz is a
  # native-toolchain member, so it stays on the staging (AutotoolsRootfs) model
  # -- an additive install would overwrite the xz already present in the rootfs.
  #
  # Two gen1 substitutions: use gen1 kernel headers because plain linux_headers
  # builds in native_toolchain_deps (which contains xz), an xz <-> linux_headers
  # cycle; and use xz_gen1 (not the full xz built here) to unpack the .tar.xz
  # source, avoiding a self-cycle. Both gen1 packages build in the external
  # buildpack rootfs and their content is equivalent.
  let xz_build_deps = [
    pkgs.linux_headers_gen1,
    pkgs.glibc,
    pkgs.binutils,
    pkgs.gcc,
    pkgs.bash,
    pkgs.make,
    pkgs.coreutils,
    pkgs.gawk,
    pkgs.sed,
    pkgs.grep,
    pkgs.tar,
    pkgs.gzip,
    pkgs.xz_gen1,
    pkgs.patch,
    pkgs.findutils,
    pkgs.diffutils,
  ]
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
      _rootfs =
        br.build_rootfs_closure pkgs "xz-%{version}-build-rootfs" xz_build_deps,
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
