let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let patch_src = fun version => fun hash => {
    name = "patch-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "2.8",
    source_object_hash | default = "f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3",
    name = "patch-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = patch_src version source_object_hash,
    },
  }
  in

  let patch = {
    version | default = "2.8",
    source_object_hash | default = "f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3",
    name = "patch-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "patch-build-rootfs" [],
      source = patch_src version source_object_hash,
    },
  }
  in

  {
    include [
      patch_gen1,
      patch,
    ],
  }
