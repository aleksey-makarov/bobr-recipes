fun pkgs =>
  let buildpack_deps_rootfs = {
    name = "buildpack-deps-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.buildpack_deps_image,
    },
  }
  in

  let alpine_rootfs = {
    name = "alpine-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.alpine_image,
    },
  }
  in

  let ubuntu_rootfs = {
    name = "ubuntu-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.ubuntu_image,
    },
  }
  in

  let busybox_rootfs = {
    name = "busybox-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.busybox_image,
    },
  }
  in

  let golang_rootfs = {
    name = "golang-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.golang_image,
    },
  }
  in

  let python_slim_rootfs = {
    name = "python-slim-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.python_slim_image,
    },
  }
  in

  {
    include [
      buildpack_deps_rootfs,
      alpine_rootfs,
      ubuntu_rootfs,
      busybox_rootfs,
      golang_rootfs,
      python_slim_rootfs,
    ],
  }
