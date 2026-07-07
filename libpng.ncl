let version = "1.6.50" in

fun pkgs =>
  let libpng_src = {
    name = "libpng-src-%{version}",
    tag = "Source",
    object_hash = "82043e583b2bca3038fd18826a48191e25ef9958905047273a69d4f5a8f66c60",
    origin = {
      tag = "Http",
      # Canonical SourceForge project path (+ /download fallback), matching the
      # other SF-hosted recipes. The short download.sourceforge.net/libpng/ form
      # goes through an extra HTML redirect the fetcher can capture by mistake.
      url = [
        "https://downloads.sourceforge.net/project/libpng/libpng16/%{version}/libpng-%{version}.tar.xz",
        "https://sourceforge.net/projects/libpng/files/libpng16/%{version}/libpng-%{version}.tar.xz/download",
      ],
    },
  }
  in

  let libpng = {
    name = "libpng-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.zlib,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
      # `make install` only lays down libpng16.pc; add the unversioned
      # libpng.pc symlink so `pkg-config libpng` (used by freetype/cairo)
      # resolves without falling back to a WrapDB download.
      post_install = {
        name = "libpng_pc_symlink",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          "ln -sfv libpng16.pc \"@{out}/usr/lib/pkgconfig/libpng.pc\"",
        ],
      },
    },
    inputs = {
      source = libpng_src,
    },
  }
  in

  {
    include [
      libpng,
    ],
  }
