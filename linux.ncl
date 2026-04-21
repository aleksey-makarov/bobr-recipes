let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkg_name = "linux" in
  let pkg_version = "6.18.10" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let headers_script_name = "buildscript-linux-headers-%{pkg_version}" in
  let headers_name = "linux-headers-%{pkg_version}" in

  let linux_src = {
    name = source_name,
    tag = "Fetch",
    config = {
      url = "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz",
      hash = "md5:660e706a43f634b1fcd911f8839d2f61",
    },
    inputs = {},
  }
  in

  let buildscript_linux_headers = {
    name = headers_script_name,
    tag = "Text",
    config = {
      executable = true,
      source = import "linux-headers.sh" as 'Text,
    },
    inputs = {},
  }
  in

  let linux_headers = {
    name = headers_name,
    tag = "Binary",
    config = {
      steps = [
        {
          name = "configure",
          run_as = "build-user",
          cwd = "${build}",
          argv = ["${script}", "configure"],
          env = {
            MBUILD_SOURCE_DIR = "${source}",
            MBUILD_INSTALL_DIR = "${out}",
          },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "${build}",
          argv = ["${script}", "build"],
          env = {
            MBUILD_SOURCE_DIR = "${source}",
            MBUILD_INSTALL_DIR = "${out}",
          },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "${build}",
          argv = ["${script}", "install"],
          env = {
            MBUILD_SOURCE_DIR = "${source}",
            MBUILD_INSTALL_DIR = "${out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      image = pkgs.host_image,
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
