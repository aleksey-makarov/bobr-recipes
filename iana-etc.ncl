fun pkgs =>
  let iana_etc_src = {
    name = "iana-etc-src-20250807",
    tag = "Source",
    object_hash = "0b860de93a69527dd8b72156779c94e324b66831b89853a0b4ea672c21a8a431",
    origin = {
      type = "http",
      url = "https://github.com/Mic92/iana-etc/releases/download/20250807/iana-etc-20250807.tar.gz",
    },
    meta = {},
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
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_SOURCE_DIR = "@{source}",
            MBUILD_INSTALL_DIR = "@{out}",
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
