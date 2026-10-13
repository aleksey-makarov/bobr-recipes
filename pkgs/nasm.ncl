# NASM (Netwide Assembler) -- a BUILD tool only. mozjs/SpiderMonkey's configure
# probes for it; it never ships in a runtime rootfs. Plain autotools, so the
# `Autotools` synthetic builder handles it out of the box.
# Configure version and hash through `pkgs.nasm_src`.
fun pkgs =>
  let nasm_src = {
    version | default = "2.16.03",
    name = "nasm-src-%{version}",
    tag = "Source",
    object_hash | default = "1412a1c760bbd05db026b6c0d1657affd6631cd0a63cddb6f73cc6d4aa616148",
    origin = {
      tag = "Http",
      url = "https://www.nasm.us/pub/nasm/releasebuilds/%{version}/nasm-%{version}.tar.xz",
    },
  }
  in

  let nasm = {
    name = "nasm-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.nasm_src,
    },
  }
  in

  {
    include [
      nasm_src,
      nasm,
    ],
  }
