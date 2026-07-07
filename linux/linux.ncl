let recipe = import "../recipe-lib.ncl" in
let version = "7.0.9" in
let major_version =
  let matched = std.string.find "^([0-9]+)[.]" version in
  if matched.index == 0 && std.array.length matched.groups == 1 then
    std.array.at 0 matched.groups
  else
    std.fail_with "linux.ncl: version must start with a major version"
in
let hashes = {
  "6.18.10" = "91c880a309524138bf58dda3187ffa58e1656b95857b9a43ce772d09fb59a4f5",
  "7.0.9"   = "6e78d8e1838519b60d5c5af1df344fee13d281a7fbbdccb01b0ef3bbc8ca3a4f",
} in

fun pkgs =>
  let linux_source = {
    name = "linux-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/kernel/v%{major_version}.x/linux-%{version}.tar.xz",
    },
  }
  in

  let linux_config = {
    name = "linux-config-%{version}",
    tag = "Source",
    object_hash = import ".config.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "linux/.config",
    },
  }
  in

  let buildscript_linux = {
    name = "buildscript-linux",
    tag = "Source",
    object_hash = import "linux.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "linux/linux.sh",
    },
  }
  in

  # Kernel UAPI headers are config-independent: `make headers` extracts them
  # from the source tree and generates the rest (`linux/version.h`, the
  # asm-generic wrapper headers) without ever consuming `.config`. The two
  # variants are the *same* recipe and differ only in the rootfs they build in:
  #   - gen1: the OCI-derived buildpack rootfs, used to bootstrap system-rootfs
  #     before a self-hosted toolchain exists;
  #   - plain: our self-hosted `system_rootfs_2`, so regular packages compile
  #     against the same headers the toolchain itself was built against.
  let mk_linux_headers = fun variant =>
    fun rootfs =>
      let headers_env = {
        BOBR_LINUX_BUILD_KIND = "headers",
        BOBR_SOURCE_DIR = "@{build}/source",
        BOBR_INSTALL_DIR = "@{out}",
      }
      in
      {
        name = "linux-headers%{variant}-%{version}",
        tag = "SandboxBuildRootfs",
        config = {
          steps = [
            recipe.prepare_source_step,
            {
              name = "configure",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}"],
              env = headers_env,
            },
            {
              name = "build",
              run_as = "build-user",
              cwd = "@{build}",
              argv = ["@{script}"],
              env = headers_env,
            },
            {
              name = "install",
              run_as = "root",
              cwd = "@{build}",
              argv = ["@{script}"],
              env = headers_env,
            },
          ],
          script_config = {},
        },
        inputs = {
          _rootfs = rootfs,
          script = buildscript_linux,
          source = linux_source,
        },
      }
  in

  let linux_headers_gen1 = mk_linux_headers "-gen1" pkgs.buildpack_deps_rootfs in
  let linux_headers = mk_linux_headers "" pkgs.system_rootfs_2 in

  let linux = {
    name = "linux-%{version}",
    tag = "SandboxBuild",
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
            BOBR_LINUX_BUILD_KIND = "full",
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            BOBR_LINUX_BUILD_KIND = "full",
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "@{out}",
          },
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            BOBR_LINUX_BUILD_KIND = "full",
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "@{out}",
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

  # Extract the kernel image out of the linux fs-tree into a plain object
  # (a directory holding a single `bzImage`), so tools can use it directly
  # without poking into fs-files by hash.
  let linux_bzimage = {
    name = "linux-bzimage-%{version}",
    tag = "FsTreeExport",
    config = {
      copies = [
        { from = "boot/bzImage", to = "bzImage" },
      ],
    },
    inputs = {
      input = linux,
    },
  }
  in

  {
    include [
      linux_headers_gen1,
      linux,
      linux_headers,
      linux_bzimage,
    ],
  }
