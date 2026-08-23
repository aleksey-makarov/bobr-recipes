# libfyaml -- YAML 1.2 parser/emitter required by AppStream 1.x. Build the
# latest stable release without development-only network tests or host-specific
# SIMD targets.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libfyaml_src = fun version => fun hash => {
    name = "libfyaml-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://github.com/pantoniou/libfyaml/releases/download/v%{version}/libfyaml-%{version}.tar.gz",
        "https://downloads.yoctoproject.org/mirror/sources/libfyaml-%{version}.tar.gz",
      ],
    },
  }
  in

  let libfyaml = {
    version | default = "0.9.6",
    source_object_hash | default = "a59cc3331e2eb903ec36933ad52a45888041cac31e44f553a00511131242c483",
    name = "libfyaml-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-network",
        "--disable-devmode",
        "--enable-portable-target",
      ],
    },
    inputs = {
      source = libfyaml_src version source_object_hash,
    },
  }
  in

  {
    include [
      libfyaml,
    ],
  }
