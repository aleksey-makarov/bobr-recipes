fun pkgs =>
  let libpipeline_src = {
    version | default = "1.5.8",
    name = "libpipeline-src-%{version}",
    tag = "Source",
    object_hash | default = "1b1203ca152ccd63983c3f2112f7fe6fa5afd453218ede5153d1b31e11bb8405",
    origin = {
      tag = "Http",
      url = [
        "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-%{version}.tar.gz",
        "https://deb.debian.org/debian/pool/main/libp/libpipeline/libpipeline_%{version}.orig.tar.gz",
        "https://tarballs.nixos.org/sha256/%{object_hash}",
      ],
    },
  }
  in

  let libpipeline = {
    name = "libpipeline-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.libpipeline_src,
    },
  }
  in

  {
    include [
      libpipeline_src,
      libpipeline,
    ],
  }
