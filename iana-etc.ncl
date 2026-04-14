let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iana_etc_src =
    recipe.fetch "iana-etc-src-20250807" {
      url = "https://github.com/Mic92/iana-etc/releases/download/20250807/iana-etc-20250807.tar.gz",
      hash = "md5:de0a909103d4ff59d1424c5ec7ac9e4a",
    }
  in

  let buildscript_iana_etc =
    recipe.text "buildscript-iana-etc" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"
        mkdir -p "/out/${out}/etc"
        install -m 0644 services "/out/${out}/etc/services"
        install -m 0644 protocols "/out/${out}/etc/protocols"
      "%,
    }
  in

  let iana_etc =
    recipe.binary "iana-etc-20250807" {
      script_config = {},
    } pkgs.system_image buildscript_iana_etc [iana_etc_src]
  in

  {
    include [
      iana_etc_src,
      buildscript_iana_etc,
      iana_etc,
    ],
  }
