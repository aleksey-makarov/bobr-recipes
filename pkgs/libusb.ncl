# libusb -- USB access library, needed by libgusb (-> colord -> mutter). udev
# hotplug off (device enumeration via sysfs) to avoid a libudev build dep here.
# Configure version and hash through `pkgs.libusb_src`.
fun pkgs =>
  let libusb_src = {
    version | default = "1.0.30",
    name = "libusb-src-%{version}",
    tag = "Source",
    object_hash | default = "fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf",
    origin = {
      tag = "Http",
      url = "https://github.com/libusb/libusb/releases/download/v%{version}/libusb-%{version}.tar.bz2",
    },
  }
  in

  let libusb = {
    name = "libusb-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-udev",
      ],
    },
    inputs = {
      source = pkgs.libusb_src,
    },
  }
  in

  {
    include [
      libusb_src,
      libusb,
    ],
  }
