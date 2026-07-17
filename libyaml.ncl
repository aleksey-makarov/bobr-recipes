# libyaml -- YAML 1.1 parser/emitter (provides yaml-0.1). Pulled in as a
# dependency of AppStream (YAML metadata parsing). Plain Autotools build with no
# external dependencies.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libyaml_src = fun version =>
    fun hash =>
      {
        name = "libyaml-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/yaml/libyaml/releases/download/%{version}/yaml-%{version}.tar.gz",
        },
      }
  in

  let libyaml = {
    version | default = "0.2.5",
    source_object_hash
      | default
      = "c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4",
    name = "libyaml-%{version}",
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
      ],
    },
    inputs = {
      source = libyaml_src version source_object_hash,
    },
  }
  in

  {
    include [
      libyaml,
    ],
  }
