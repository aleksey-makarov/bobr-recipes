# libseccomp -- syscall-filtering library, required by glycin's libglycin (it
# sandboxes image loaders with seccomp). Plain C autotools library. The release
# tarball ships the pre-generated gperf syscall table (`syscalls.perf.c`), but
# `gperf` is kept as a build dep since configure probes for it.
# Configure version and hash through `pkgs.libseccomp_src`.
fun pkgs =>
  let libseccomp_src = {
    version | default = "2.6.0",
    name = "libseccomp-src-%{version}",
    tag = "Source",
    object_hash | default = "83b6085232d1588c379dc9b9cae47bb37407cf262e6e74993c61ba72d2a784dc",
    origin = {
      tag = "Http",
      url = "https://github.com/seccomp/libseccomp/releases/download/v%{version}/libseccomp-%{version}.tar.gz",
    },
  }
  in

  let libseccomp = {
    name = "libseccomp-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gperf,
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
      source = pkgs.libseccomp_src,
    },
  }
  in

  {
    include [
      libseccomp_src,
      libseccomp,
    ],
  }
