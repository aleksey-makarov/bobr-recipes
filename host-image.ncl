let recipe = import "recipe-lib.ncl" in

fun _pkgs =>
  let host_image = {
    name = "host-image",
    tag = "Source",
    object_hash = "8b756c34b08e647440dba069e9216bee80e616030f7ac26501dcab5c4a91babe",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/buildpack-deps:bookworm",
      digest = "sha256:58c016c3359fc99b33db9dbf1d16bb55b911d0a83248577606cea280f978e6e4",
    },
    meta = {},
  }
  in

  {
    include [host_image],
  }
