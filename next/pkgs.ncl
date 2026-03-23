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
  & ((import "make.ncl") pkgs)
  & ((import "coreutils.ncl") pkgs)
  & ((import "sed.ncl") pkgs)
  & ((import "grep.ncl") pkgs)
  & ((import "gzip.ncl") pkgs)
  & ((import "tar.ncl") pkgs)
  & ((import "patch.ncl") pkgs)
  & ((import "findutils.ncl") pkgs)
  & ((import "diffutils.ncl") pkgs)
  & ((import "m4.ncl") pkgs)
  & ((import "python.ncl") pkgs)
  & ((import "bash.ncl") pkgs)
  & ((import "gawk.ncl") pkgs)
  & ((import "bison.ncl") pkgs)
  & ((import "gmp.ncl") pkgs)
  & ((import "mpfr.ncl") pkgs)
  & ((import "mpc.ncl") pkgs)
  & ((import "gcc.ncl") pkgs)
  & ((import "glibc.ncl") pkgs)
  & ((import "base-filesystem.ncl") pkgs)
  & ((import "bootstrap-image.ncl") pkgs)
  & ((import "build-image.ncl") pkgs)
in
pkgs
