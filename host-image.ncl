let recipe = import "recipe-lib.ncl" in

fun _pkgs =>
  let host_image =
    {
      name = "host-image",
      tag = "ContainerImage",
      config = {
      image = "docker.io/library/buildpack-deps:bookworm",
      digest = "sha256:58c016c3359fc99b33db9dbf1d16bb55b911d0a83248577606cea280f978e6e4",
    },
      inputs = {},
    }
  in

  {
    include [host_image],
  }
