let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let patch_src = {
    version | default = "2.8",
    name = "patch-src-%{version}",
    tag = "Source",
    object_hash | default = "f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-%{version}.tar.xz",
      ],
    },
  }
  in

  let patch_gen1 = {
    name = "patch-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.patch_src,
    },
  }
  in

  let patch = {
    name = "patch-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "patch-build-rootfs" [],
      source = pkgs.patch_src,
    },
  }
  in

  {
    include [
      patch_src,
      patch_gen1,
      patch,
    ],
  }
