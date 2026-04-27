let recipe = import "recipe-lib.ncl" in

fun _pkgs =>
  let host_image = {
    name = "host-image",
    tag = "Source",
    object_hash = "eb5612a05295a5d7a9931677d7cafc1ed686db6586d353cad25cdd1fc95d73e7",
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
