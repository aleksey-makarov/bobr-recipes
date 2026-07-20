let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = fun version => fun hash => {
    name = "zlib-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://zlib.net/fossils/zlib-%{version}.tar.gz",
    },
  }
  in

  let zlib = {
    version | default = "1.3.1",
    source_object_hash | default = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
    name = "zlib-%{version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
      ],
      # zlib's hand-written Makefile runs a bare `ldconfig` ($(LDCONFIG) in
      # install-libs), which writes the live /etc/ld.so.cache -- outside the
      # /stage tree AutotoolsStageRootfs captures, so TreeMove would choke on it.
      # Neutralise it: ld.so.cache is a whole-system file regenerated over the
      # complete image at finalize, so no package build should emit it. Distros
      # get away with it because their DESTDIR/non-root builds make ldconfig fail
      # silently; we make it an explicit no-op. zlib is the only package here with
      # a bare (non-DESTDIR) ldconfig -- everything else is autotools-clean.
      make_args = [
        "LDCONFIG=true",
      ],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "zlib-build-rootfs" [],
      source = zlib_src version source_object_hash,
    },
  }
  in

  {
    include [
      zlib,
    ],
  }
