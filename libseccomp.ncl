# libseccomp -- syscall-filtering library, required by glycin's libglycin (it
# sandboxes image loaders with seccomp). Plain C autotools library. The release
# tarball ships the pre-generated gperf syscall table (`syscalls.perf.c`), but
# `gperf` is kept as a build dep since configure probes for it.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "2.6.0" in
let default_hashes = {
  "2.6.0" = "83b6085232d1588c379dc9b9cae47bb37407cf262e6e74993c61ba72d2a784dc",
}
in

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
    version | default = default_version,
    hashes | default = default_hashes,
    name = "libseccomp-%{version}",
    tag = "Autotools",
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libseccomp,
    ],
  }
