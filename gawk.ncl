let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gawk_src = {
    name = "gawk-src-5.3.2",
    tag = "Source",
    object_hash = "c602835611656dd7e6eaa74419f7f8856e73033c4b0ca0149c79124496e0c25a",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-5.3.2.tar.xz",
      ],
    },
  }
  in

  let gawk_gen1 = {
    name = "gawk-gen1-5.3.2",
    tag = "Autotools",
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
            if [ -L "@{out}/usr/bin/awk" ]; then
              rm -v "@{out}/usr/bin/awk"
            elif [ -e "@{out}/usr/bin/awk" ]; then
              echo "refusing to remove non-symlink @{out}/usr/bin/awk" >&2
              exit 1
            fi
          "%,
        ],
      },
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = gawk_src,
    },
  }
  in

  let awk_symlink = {
    name = "awk-symlink",
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
      install = {
        rules = [
          recipe.install.root_default_rule,
        ],
      },
    },
    inputs = {},
  }
  in

  let gawk = {
    name = "gawk-5.3.2",
    tag = "Autotools",
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
      rootfs = pkgs.system_rootfs_1,
      source = gawk_src,
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
