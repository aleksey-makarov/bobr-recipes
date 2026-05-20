let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let pkg_name = "linux" in
  let pkg_version = "6.18.10" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let script_name = "buildscript-linux-%{pkg_version}" in
  let headers_gen1_name = "linux-headers-gen1-%{pkg_version}" in
  let headers_name = "linux-headers-%{pkg_version}" in

  let linux_source = {
    name = source_name,
    tag = "Source",
    object_hash = "91c880a309524138bf58dda3187ffa58e1656b95857b9a43ce772d09fb59a4f5",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz",
    },
  }
  in

  let linux_config = {
    name = "linux-config-%{pkg_version}",
    tag = "Source",
    object_hash = import ".config.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "linux/.config",
      mode = "direct",
    },
  }
  in

  let buildscript_linux = {
    name = script_name,
    tag = "Source",
    object_hash = import "linux.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "linux/linux.sh",
      mode = "direct",
    },
  }
  in

  let linux_headers_gen1 = {
    name = headers_gen1_name,
    tag = "Sandbox",
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_LINUX_BUILD_KIND = "headers",
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_LINUX_BUILD_KIND = "headers",
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_LINUX_BUILD_KIND = "headers",
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      script = buildscript_linux,
      source = linux_source,
    },
  }
  in

  let linux = {
    name = pkg_name,
    tag = "SandboxPackage",
    deps = {
      build = [
        pkgs.linux_headers_gen1,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.bash,
        pkgs.make,
        pkgs.coreutils,
        pkgs.gawk,
        pkgs.sed,
        pkgs.grep,
        pkgs.findutils,
        pkgs.diffutils,
        pkgs.bc,
        pkgs.bison,
        pkgs.flex,
        pkgs.zlib,
        pkgs.elfutils,
        pkgs.perl,
        pkgs.rsync,
      ],
      runtime = [],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_LINUX_BUILD_KIND = "full",
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_LINUX_BUILD_KIND = "full",
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_LINUX_BUILD_KIND = "full",
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_linux,
      source = linux_source,
      kernel_config = linux_config,
    },
  }
  in

  let linux_headers = {
    name = headers_name,
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [],
    },
    config = {
      include = ["usr/include/**"],
    },
    inputs = {
      tree = linux,
    },
  }
  in

  {
    include [
      linux_headers_gen1,
      linux,
      linux_headers,
    ],
  }
