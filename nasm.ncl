# NASM (Netwide Assembler) -- a BUILD tool only. mozjs/SpiderMonkey's configure
# probes for it; it never ships in a runtime rootfs. Plain autotools, so the
# `Autotools` synthetic builder handles it out of the box.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let nasm_src = fun version =>
    fun hash =>
      {
        name = "nasm-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.nasm.us/pub/nasm/releasebuilds/%{version}/nasm-%{version}.tar.xz",
        },
      }
  in

  let nasm = {
    version | default = "2.16.03",
    source_object_hash
      | default
      = "1412a1c760bbd05db026b6c0d1657affd6631cd0a63cddb6f73cc6d4aa616148",
    name = "nasm-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {},
    inputs = {
      source = nasm_src version source_object_hash,
    },
  }
  in

  {
    include [
      nasm,
    ],
  }
