let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let gawk_src = {
    version | default = "5.3.2",
    name = "gawk-src-%{version}",
    tag = "Source",
    object_hash | default = "f8c3486509de705192138b00ef2c00bbbdd0e84c30d5c07d23fc73a9dc4cc9cc",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-%{version}.tar.xz",
      ],
    },
  }
  in

  let gawk_gen1 = {
    name = "gawk-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--without-readline"],
      pre_configure = {
        name = "prepare_source",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i 's/extras//' Makefile.in",
        ],
      },
      post_install = {
        name = "remove_awk_symlink",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            if [ -L "/stage/usr/bin/awk" ]; then
              rm -v "/stage/usr/bin/awk"
            elif [ -e "/stage/usr/bin/awk" ]; then
              echo "refusing to remove non-symlink /stage/usr/bin/awk" >&2
              exit 1
            fi
          "%,
        ],
      },
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.gawk_src,
    },
  }
  in

  let awk_symlink_files = {
    name = "awk-symlink-files",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          {
            type = "symlink",
            path = "usr/bin/awk",
            target = "gawk",
          },
        ],
      },
    },
    inputs = {},
  }
  in

  let awk_symlink = {
    name = "awk-symlink",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = awk_symlink_files,
    },
  }
  in

  let gawk = {
    name = "gawk-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--without-readline"],
      pre_configure = {
        name = "prepare_source",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i 's/extras//' Makefile.in",
        ],
      },
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "gawk-build-rootfs" [],
      source = pkgs.gawk_src,
    },
  }
  in

  {
    include [
      gawk_src,
      gawk_gen1,
      awk_symlink,
      gawk,
    ],
  }
