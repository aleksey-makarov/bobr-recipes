let recipe = import "recipe-lib.ncl" in

fun _pkgs =>
  let buildpack_deps_image = {
    name = "buildpack-deps-image",
    tag = "Source",
    object_hash = "8b756c34b08e647440dba069e9216bee80e616030f7ac26501dcab5c4a91babe",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/buildpack-deps:bookworm",
      digest = "sha256:58c016c3359fc99b33db9dbf1d16bb55b911d0a83248577606cea280f978e6e4",
    },
  }
  in

  let alpine_image = {
    name = "alpine-image",
    tag = "Source",
    object_hash = "a3da1984858045386db71d8560666b29c0384ce05dffcb143efa655aac22defe",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/alpine:3.23",
      digest = "sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11",
    },
  }
  in

  let ubuntu_image = {
    name = "ubuntu-image",
    tag = "Source",
    object_hash = "646ca5df2ed5ef42cb04f259c44c0fb0a68bb761d21ff49cc7689d7a12c3ad56",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/ubuntu:24.04",
      digest = "sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b",
    },
  }
  in

  let busybox_image = {
    name = "busybox-image",
    tag = "Source",
    object_hash = "d4d8b4eb7a8715dec666576bfd9cc82c7d3dd3de4ce9734424995a7be325e0f3",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/busybox:1.37",
      digest = "sha256:1487d0af5f52b4ba31c7e465126ee2123fe3f2305d638e7827681e7cf6c83d5e",
    },
  }
  in

  let golang_image = {
    name = "golang-image",
    tag = "Source",
    object_hash = "be4c323b61969f2e8b87b1f41a3b1e2e58f3fa321fcc679d444af356a8b78f93",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/golang:1-bookworm",
      digest = "sha256:47ce5636e9936b2c5cbf708925578ef386b4f8872aec74a67bd13a627d242b19",
    },
  }
  in

  let python_slim_image = {
    name = "python-slim-image",
    tag = "Source",
    object_hash = "f3ee5fba1d26441d4cf95c9fa05c2d4a8ee647a5e0c9f07f339e101db1c96078",
    origin = {
      type = "oci-registry",
      image = "docker.io/library/python:3-slim-bookworm",
      digest = "sha256:2e256d0381371566ed96980584957ed31297f437569b79b0e5f7e17f2720e53a",
    },
  }
  in

  {
    include [
      buildpack_deps_image,
      alpine_image,
      ubuntu_image,
      busybox_image,
      golang_image,
      python_slim_image,
    ],
  }
