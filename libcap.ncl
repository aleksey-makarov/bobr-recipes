let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libcap_src = fun version =>
    fun hash =>
    {
      name = "libcap-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-%{version}.tar.xz",
      },
    }
  in

  let libcap = {
    version | default = "2.78",
    source_object_hash | default = "0d621e562fd932ccf67b9660fb018e468a683d7b827541df27813228c996bb11",
    name = "libcap-%{version}",
    tag = "Makefile",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
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
      # libcap's `make install` runs ldconfig, which writes /etc/ld.so.cache.
      # Under the additive model that lands in the captured layer; the tree's
      # ld.so.cache is a finalize artifact (gnome-finalize regenerates it), so
      # no package may ship one. Drop our freshly written copy (the build rootfs
      # ships none, so this is additive).
      post_install = {
        name = "drop_ld_so_cache",
        run_as = "root",
        argv = ["rm", "-fv", "/etc/ld.so.cache"],
      },
    },
    inputs = {
      source = libcap_src version source_object_hash,
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
