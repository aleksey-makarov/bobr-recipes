fun pkgs =>
  let iana_etc_src = {
    name = "iana-etc-src-20250807",
    tag = "Fetch",
    config = {
      url = "https://github.com/Mic92/iana-etc/releases/download/20250807/iana-etc-20250807.tar.gz",
      hash = "md5:de0a909103d4ff59d1424c5ec7ac9e4a",
    },
    inputs = {},
  }
  in

  let buildscript_iana_etc = {
    name = "buildscript-iana-etc",
    tag = "Text",
    config = {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        cd "${MBUILD_SOURCE_DIR}"
        mkdir -p "${MBUILD_INSTALL_DIR}/etc"
        install -m 0644 services "${MBUILD_INSTALL_DIR}/etc/services"
        install -m 0644 protocols "${MBUILD_INSTALL_DIR}/etc/protocols"
      "%,
    },
    inputs = {},
  }
  in

  let iana_etc = {
    name = "iana-etc-20250807",
    tag = "Binary",
    config = {
      steps = [
        {
          name = "install",
          run_as = "root",
          cwd = "${build}",
          argv = ["${script}"],
          env = {
            MBUILD_SOURCE_DIR = "${source}",
            MBUILD_INSTALL_DIR = "${out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      image = pkgs.system_image,
      script = buildscript_iana_etc,
      source = iana_etc_src,
    },
  }
  in

  {
    include [
      iana_etc_src,
      buildscript_iana_etc,
      iana_etc,
    ],
  }
