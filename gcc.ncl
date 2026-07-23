let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gcc_src = fun version => fun hash => {
    name = "gcc-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/gcc/gcc-%{version}/gcc-%{version}.tar.xz",
      ],
    },
  }
  in

  let gcc_prereqs_pre_configure = {
    name = "prepare_gcc_prereqs",
    run_as = "build-user",
    argv = [
      "/bin/sh",
      "-ec",
      m%"
        unpack_prereq() {
          name="$1"
          archive="$2"
          tmp="$(mktemp -d)"
          tar -C "$tmp" -xf "$archive"
          set -- "$tmp"/*
          if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
            echo "expected one top-level directory in $archive" >&2
            exit 1
          fi
          rm -rf "$name"
          mv "$1" "$name"
          rmdir "$tmp"
        }

        unpack_prereq gmp "@{gmp}"
        unpack_prereq mpfr "@{mpfr}"
        unpack_prereq mpc "@{mpc}"
      "%,
    ],
  }
  in

  let gcc_gen1 = {
    version | default = "15.2.0",
    source_object_hash | default = "438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e",
    name = "gcc-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      pre_configure = gcc_prereqs_pre_configure,
      configure_args = [
        "--enable-languages=c,c++",
        "--disable-multilib",
        "--disable-bootstrap",
        "--disable-fixincludes",
        "--disable-nls",
        "--without-zstd",
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = gcc_src version source_object_hash,
      gmp = pkgs.gmp.inputs.source,
      mpfr = pkgs.mpfr.inputs.source,
      mpc = pkgs.mpc.inputs.source,
    },
  }
  in

  let gcc = {
    version | default = "15.2.0",
    source_object_hash | default = "438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e",
    name = "gcc-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      pre_configure = gcc_prereqs_pre_configure,
      configure_args = [
        "--enable-languages=c,c++",
        "--enable-default-pie",
        "--enable-default-ssp",
        "--disable-multilib",
        "--disable-bootstrap",
        "--disable-fixincludes",
        "--disable-nls",
        "--without-zstd",
      ],
      post_install = {
        name = "add_cc_symlink",
        run_as = "root",
        argv = [
          "ln",
          "-sv",
          "gcc",
          "/stage/usr/bin/cc",
        ],
      },
    },
    inputs = {
      _rootfs = recipe.gen1_toolchain_rootfs pkgs "gcc-build-rootfs" [],
      source = gcc_src version source_object_hash,
      gmp = pkgs.gmp.inputs.source,
      mpfr = pkgs.mpfr.inputs.source,
      mpc = pkgs.mpc.inputs.source,
    },
  }
  in

  let gcc_libs =
    recipe.split.libs
      gcc
      [
        "usr/lib64/libgcc_s.so.1",
        "usr/lib64/libgomp.so.1",
        "usr/lib64/libgomp.so.1.0.0",
        "usr/lib64/libstdc++.so.6",
        "usr/lib64/libstdc++.so.6.0.34",
      ]
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
      gcc_gen1,
      gcc,
      gcc_libs,
    ],
  }
