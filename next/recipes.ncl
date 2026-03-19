let pkgs = {
  binutils = import "binutils.ncl",
} in
pkgs.binutils.temp
