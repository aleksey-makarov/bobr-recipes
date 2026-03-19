let lib = import "lib.ncl" in
let mk_binutils = import "binutils.ncl" in
let mk_linux = import "linux.ncl" in

let rec pkgs =
  {
    host_image =
      store.container_image lib.host_image_name {
        image = lib.host_image.image,
        digest = lib.host_image.digest,
      },
  }
  & (mk_binutils pkgs)
  & (mk_linux pkgs)
in
pkgs
