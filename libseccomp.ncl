# libseccomp -- syscall-filtering library, required by glycin's libglycin (it
# sandboxes image loaders with seccomp). Plain C autotools library. The release
# tarball ships the pre-generated gperf syscall table (`syscalls.perf.c`), but
# `gperf` is kept as a build dep since configure probes for it.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libseccomp-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/seccomp/libseccomp/releases/download/v%{version}/libseccomp-%{version}.tar.gz",
        },
      }
  in

  let libseccomp = {
    version | default = "2.6.0",
    source_object_hash | default = "83b6085232d1588c379dc9b9cae47bb37407cf262e6e74993c61ba72d2a784dc",
    name = "libseccomp-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.gperf,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libseccomp,
    ],
  }
