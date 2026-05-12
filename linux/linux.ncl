let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let pkg_name = "linux" in
  let pkg_version = "6.18.10" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let headers_script_name = "buildscript-linux-headers-%{pkg_version}" in
  let headers_name = "linux-headers-%{pkg_version}" in

  let linux_src = {
    name = source_name,
    tag = "Source",
    object_hash = "91c880a309524138bf58dda3187ffa58e1656b95857b9a43ce772d09fb59a4f5",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz",
    },
    meta = {},
  }
  in

  let buildscript_linux_headers = {
    name = headers_script_name,
    tag = "Source",
    object_hash = import "linux-headers.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "linux/linux-headers.sh",
      mode = "direct",
    },
    meta = {},
  }
  in

  let linux_headers = {
    name = headers_name,
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "configure"],
          env = {
            MBUILD_SOURCE_DIR = "@{source}",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "build"],
          env = {
            MBUILD_SOURCE_DIR = "@{source}",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "install"],
          env = {
            MBUILD_SOURCE_DIR = "@{source}",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      script = buildscript_linux_headers,
      source = linux_src,
    },
  }
  in

  {
    include [
      linux_src,
      linux_headers,
    ],
  }
