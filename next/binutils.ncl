let lib = import "lib.ncl" in

let pkg_name = "binutils" in
let pkg_version = "2.45" in

let source_name = "%{pkg_name}-src-%{pkg_version}" in
let temp_script_name = "buildscript-%{pkg_name}-temp-%{pkg_version}" in
let temp_name = "%{pkg_name}-temp-%{pkg_version}" in

let host_image_build =
  store.container_image lib.host_image_name {
    image = lib.host_image.image,
    digest = lib.host_image.digest,
  }
in

let src_build =
  store.fetch source_name {
    url = [
      "https://sourceware.org/pub/binutils/releases/binutils-2.45.tar.xz",
      "https://mirrors.kernel.org/gnu/binutils/binutils-2.45.tar.xz",
    ],
    hash = "md5:dee5b4267e0305a99a3c9d6131f45759",
  }
in

let temp_script_build =
  store.text temp_script_name {
    kind = "build-script",
    source = m%"
      #!/usr/bin/env bash
      set -euo pipefail

      src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
      out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

      cd "/in/${src}"

      if [ ! -x ./configure ]; then
        candidates=()
        for d in ./*; do
          if [ -d "$d" ] && [ -x "$d/configure" ]; then
            candidates+=("$d")
          fi
        done
        if [ "${#candidates[@]}" -eq 1 ]; then
          cd "${candidates[0]}"
        fi
      fi

      export PATH="/tools/bin:${PATH:-}"

      mkdir -p build
      cd build

      ../configure                               \
        --prefix=/tools                          \
        --with-sysroot=/                         \
        --target=x86_64-lfs-linux-gnu           \
        --disable-nls                            \
        --enable-gprofng=no                      \
        --disable-werror                         \
        --enable-new-dtags                       \
        --enable-default-hash-style=gnu

      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      make -j"${jobs}"
      make DESTDIR="/out/${out}" install
      "%,
  }
in

let temp_build =
  store.bind src_build (fun src =>
  store.bind temp_script_build (fun script =>
  store.bind host_image_build (fun image =>
  store.binary temp_name {
    kind = "binary-output",
    optimize = "size",
  } image script [src])))
in

{
  pname = pkg_name,
  version = pkg_version,

  names = {
    src = source_name,
    temp_script = temp_script_name,
    temp = temp_name,
  },

  host_image = host_image_build,
  src = src_build,

  scripts = {
    temp = temp_script_build,
  },

  temp = temp_build,
}
