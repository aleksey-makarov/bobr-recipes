{
  target = "x86_64-lfs-linux-gnu",
  build = "x86_64-pc-linux-gnu",

  host_image_name = "host-image",
  host_image = {
    image = "docker.io/library/buildpack-deps:bookworm",
    digest = "sha256:b8d12fbc4f3afb47b1e8d765e688bc16c0a79310ec23a6673e28c036eed810b8",
  },
}
