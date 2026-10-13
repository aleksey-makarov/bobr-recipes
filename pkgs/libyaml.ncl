# libyaml -- YAML 1.1 parser/emitter (provides yaml-0.1). Pulled in as a
# dependency of AppStream (YAML metadata parsing). Plain Autotools build with no
# external dependencies.
# Configure version and hash through `pkgs.libyaml_src`.
fun pkgs =>
  let libyaml_src = {
    version | default = "0.2.5",
    name = "libyaml-src-%{version}",
    tag = "Source",
    object_hash | default = "c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4",
    origin = {
      tag = "Http",
      url = "https://github.com/yaml/libyaml/releases/download/%{version}/yaml-%{version}.tar.gz",
    },
  }
  in

  let libyaml = {
    name = "libyaml-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.libyaml_src,
    },
  }
  in

  {
    include [
      libyaml_src,
      libyaml,
    ],
  }
