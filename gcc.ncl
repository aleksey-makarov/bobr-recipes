let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gcc_src = {
    name = "gcc-src-15.2.0",
    tag = "Source",
    object_hash = "5002163974fe6baf248e5d19252d727f8f6c63bae12dce055bcc2e108ba2926b",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz",
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
    name = "gcc-gen1-15.2.0",
    tag = "AutotoolsRootfs",
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
      rootfs = pkgs.buildpack_deps_rootfs,
      source = gcc_src,
      gmp = pkgs.gmp_src,
      mpfr = pkgs.mpfr_src,
      mpc = pkgs.mpc_src,
    },
  }
  in

  let gcc = {
    name = "gcc-15.2.0",
    tag = "AutotoolsRootfs",
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
          "@{out}/usr/bin/cc",
        ],
      },
    },
    inputs = {
      rootfs = pkgs.system_rootfs_0,
      source = gcc_src,
      gmp = pkgs.gmp_src,
      mpfr = pkgs.mpfr_src,
      mpc = pkgs.mpc_src,
    },
  }
  in

  let gcc_libs =
    recipe.split.libs gcc [
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
      gcc_src,
      gcc_gen1,
      gcc,
      gcc_libs,
    ],
  }
