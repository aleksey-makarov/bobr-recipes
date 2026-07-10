# libusb -- USB access library, needed by libgusb (-> colord -> mutter). udev
# hotplug off (device enumeration via sysfs) to avoid a libudev build dep here.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "1.0.30" in
let default_hashes = {
  "1.0.30" = "4ca083cb2ad792c3152e64e852876ff0f04434e756327903f834178ec9a060ad",
}
in

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
    version | default = default_version,
    hashes | default = default_hashes,
    name = "libusb-%{version}",
    tag = "Autotools",
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libusb,
    ],
  }
