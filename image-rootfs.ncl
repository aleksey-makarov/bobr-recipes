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

  let buildpack_deps_rootfs_new = {
    name = "buildpack-deps-rootfs-new",
    tag = "OciExtractNew",
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

  let alpine_rootfs_new = {
    name = "alpine-rootfs-new",
    tag = "OciExtractNew",
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

  let ubuntu_rootfs_new = {
    name = "ubuntu-rootfs-new",
    tag = "OciExtractNew",
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

  let busybox_rootfs_new = {
    name = "busybox-rootfs-new",
    tag = "OciExtractNew",
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

  let golang_rootfs_new = {
    name = "golang-rootfs-new",
    tag = "OciExtractNew",
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

  let python_slim_rootfs_new = {
    name = "python-slim-rootfs-new",
    tag = "OciExtractNew",
    config = {},
    inputs = {
      image = pkgs.python_slim_image,
    },
  }
  in

  {
    include [
      buildpack_deps_rootfs,
      buildpack_deps_rootfs_new,
      alpine_rootfs,
      alpine_rootfs_new,
      ubuntu_rootfs,
      ubuntu_rootfs_new,
      busybox_rootfs,
      busybox_rootfs_new,
      golang_rootfs,
      golang_rootfs_new,
      python_slim_rootfs,
      python_slim_rootfs_new,
    ],
  }
