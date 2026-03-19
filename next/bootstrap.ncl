let lib = import "lib.ncl" in
{
  "host-image" = {
    type = "container-image",
    image = lib.host_image.image,
    digest = lib.host_image.digest,
    outputs = ["host-image"],
  },

  "bootstrap-for-gcc-temp-15.2.0" = {
    type = "image",
    inputs = [
      "host-image",
      "binutils-temp-2.45",
    ],
    outputs = ["bootstrap-for-gcc-temp-15.2.0"],
  },

  "bootstrap-for-glibc-temp-2.42" = {
    type = "image",
    inputs = [
      "bootstrap-for-gcc-temp-15.2.0",
      "gcc-temp-15.2.0",
      "linux-headers-temp-6.18.10",
    ],
    outputs = ["bootstrap-for-glibc-temp-2.42"],
  },

  "bootstrap-for-stage1-userland" = {
    type = "image",
    inputs = [
      "bootstrap-for-glibc-temp-2.42",
      "glibc-temp-2.42",
    ],
    outputs = ["bootstrap-for-stage1-userland"],
  },

  "bootstrap-image" = {
    type = "image",
    inputs = [
      "bootstrap-for-stage1-userland",
      "bash-temp-5.3",
    ],
    outputs = ["bootstrap-image"],
  },
}
