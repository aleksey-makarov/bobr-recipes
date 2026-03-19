let lib = import "lib.ncl" in

let rec pkgs =
  {
    host_image =
      store.container_image lib.host_image_name {
        image = lib.host_image.image,
        digest = lib.host_image.digest,
      },
  }
  & ((import "binutils.ncl") pkgs)
  & ((import "linux.ncl") pkgs)
  & ((import "bootstrap.ncl") pkgs)
  & ((import "gmp.ncl") pkgs)
  & ((import "mpfr.ncl") pkgs)
  & ((import "mpc.ncl") pkgs)
  & ((import "gcc.ncl") pkgs)
in
pkgs
