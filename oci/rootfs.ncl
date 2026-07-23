fun pkgs =>
  let oci_buildpack_deps_rootfs = {
    name = "oci-buildpack-deps-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.oci_buildpack_deps_image,
    },
  }
  in

  let oci_alpine_rootfs = {
    name = "oci-alpine-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.oci_alpine_image,
    },
  }
  in

  let oci_ubuntu_rootfs = {
    name = "oci-ubuntu-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.oci_ubuntu_image,
    },
  }
  in

  let oci_busybox_rootfs = {
    name = "oci-busybox-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.oci_busybox_image,
    },
  }
  in

  let oci_golang_rootfs = {
    name = "oci-golang-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.oci_golang_image,
    },
  }
  in

  let oci_python_slim_rootfs = {
    name = "oci-python-slim-rootfs",
    tag = "OciExtract",
    config = {},
    inputs = {
      image = pkgs.oci_python_slim_image,
    },
  }
  in

  {
    include [
      oci_buildpack_deps_rootfs,
      oci_alpine_rootfs,
      oci_ubuntu_rootfs,
      oci_busybox_rootfs,
      oci_golang_rootfs,
      oci_python_slim_rootfs,
    ],
  }
