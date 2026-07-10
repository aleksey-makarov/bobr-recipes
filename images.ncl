let recipe = import "recipe-lib.ncl" in

fun _pkgs =>
  let buildpack_deps_image = {
    name = "buildpack-deps-image",
    tag = "Source",
    object_hash = "8de14b48ada341b6dcdde48d100a48578a2651713ef1696947a20d40374b229f",
    origin = {
      tag = "OciRegistry",
      image = "docker.io/library/buildpack-deps:bookworm",
      digest = "sha256:4efddd9a54ddc095e672b2fdf514f1ee4d3bb6e1f6ffc988b022c75e6ea99383",
      platform = { os = "linux", architecture = "amd64" },
    },
  }
  in

  let alpine_image = {
    name = "alpine-image",
    tag = "Source",
    object_hash = "e21b275bcfc25e5316f21c218036fdef2b79b614e1dc61601c22a82fd08c5b96",
    origin = {
      tag = "OciRegistry",
      image = "docker.io/library/alpine:3.23",
      digest = "sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40",
      platform = { os = "linux", architecture = "amd64" },
    },
  }
  in

  let ubuntu_image = {
    name = "ubuntu-image",
    tag = "Source",
    object_hash = "9a4feb01d8b759bd50901ed309af8d27c3f502bc9c1dd7846c8b0d765bb40afb",
    origin = {
      tag = "OciRegistry",
      image = "docker.io/library/ubuntu:24.04",
      digest = "sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90",
      platform = { os = "linux", architecture = "amd64" },
    },
  }
  in

  let busybox_image = {
    name = "busybox-image",
    tag = "Source",
    object_hash = "2155c1b80dbeec5d299c2a002de6fbb386d1f389256cf4c3f3af90c59b1e0323",
    origin = {
      tag = "OciRegistry",
      image = "docker.io/library/busybox:1.37",
      digest = "sha256:9532d8c39891ca2ecde4d30d7710e01fb739c87a8b9299685c63704296b16028",
      platform = { os = "linux", architecture = "amd64" },
    },
  }
  in

  let golang_image = {
    name = "golang-image",
    tag = "Source",
    object_hash = "1edcfcd44a78e7feef46f1a7d18cb8a9a7217bbab909d2c7e3878c2d01bd7bd1",
    origin = {
      tag = "OciRegistry",
      image = "docker.io/library/golang:1-bookworm",
      digest = "sha256:18aedc16aa19b3fd7ded7245fc14b109e054d65d22ed53c355c899582bbb2113",
      platform = { os = "linux", architecture = "amd64" },
    },
  }
  in

  let python_slim_image = {
    name = "python-slim-image",
    tag = "Source",
    object_hash = "fe504cd10015e782658419b12701a9057e8b51116695d9dd07e17b080dc94aa3",
    origin = {
      tag = "OciRegistry",
      image = "docker.io/library/python:3-slim-bookworm",
      digest = "sha256:4ff4b92a68355dbdb52584ab3391dff8d371a61d4e063468bfd0130e3189c6d9",
      platform = { os = "linux", architecture = "amd64" },
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
