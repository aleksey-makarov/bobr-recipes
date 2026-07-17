# libusb -- USB access library, needed by libgusb (-> colord -> mutter). udev
# hotplug off (device enumeration via sysfs) to avoid a libudev build dep here.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libusb-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/libusb/libusb/releases/download/v%{version}/libusb-%{version}.tar.bz2",
        },
      }
  in

  let libusb = {
    version | default = "1.0.30",
    source_object_hash | default = "fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf",
    name = "libusb-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-udev",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libusb,
    ],
  }
