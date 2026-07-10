let recipe = import "../recipe-lib.ncl" in

# The source release. `hashes` is the catalog of known/supported kernel
# versions (its keys say which ones are officially built and tested), and
# `version` picks one. Both are node fields, so an overlay builds:
#   - a known version by overriding just `version`;
#   - a new version by overriding `version` and adding its hash to `hashes`:
#       linux = prev.linux & {
#         version = "6.19.1",
#         hashes = prev.linux.hashes & { "6.19.1" = "<sha256>" },
#       }
let default_version = "6.18.38" in
let default_hashes = {
  "6.18.38" = "ac26e508abd56e9f8b89872b6e10c49fc823bcc70d8068a5d8504c1a7c4ff045",
}
in

let major_version = fun version =>
  let matched = std.string.find "^([0-9]+)[.]" version in
  if matched.index == 0 && std.array.length matched.groups == 1 then
    std.array.at 0 matched.groups
  else
    std.fail_with "linux.ncl: version must start with a major version"
in

# The base kernel config sets (data). `use_tinyconfig` selects which one is
# merged on top of the corresponding `make` base (defconfig / tinyconfig).
# Overlays layer `config_options` over the selected set rather than editing
# these files.
let distro_config = import "distro-config.ncl" in
let tiny_config = import "tinyconfig.ncl" in

# Right-biased record merge: `overrides` win over `base`, new keys are added.
# Used so `config_options` can override individual base options with a plain
# merge, without merge-priority annotations on every base option.
let merge_over = fun base =>
  fun overrides =>
    overrides
    & (std.record.filter (fun name _ => !std.record.has_field name overrides) base)
in

# Serialize a record of kernel config options into a `merge_config.sh`
# fragment. Keys omit the CONFIG_ prefix; values are 'y / 'm / 'n, a number,
# or a string. Keys are sorted for a deterministic fragment.
let kconfig_fragment = fun options =>
  let render = fun name =>
    let value = std.record.get name options in
    if value == 'y then
      "CONFIG_%{name}=y"
    else if value == 'm then
      "CONFIG_%{name}=m"
    else if value == 'n then
      "# CONFIG_%{name} is not set"
    else if std.is_number value then
      "CONFIG_%{name}=%{std.string.from_number value}"
    else if std.is_string value then
      "CONFIG_%{name}=\"%{value}\""
    else
      std.fail_with "kconfig_fragment: option '%{name}' has an unsupported value type"
  in
  let names = std.array.sort std.string.compare (std.record.fields options) in
  std.string.join "\n" (std.array.map render names) ++ "\n"
in

fun pkgs =>
  let linux_source = fun version =>
    fun hash =>
      {
        name = "linux-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.kernel.org/pub/linux/kernel/v%{major_version version}.x/linux-%{version}.tar.xz",
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
        version | default = default_version,
        hashes | default = default_hashes,
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
          source = linux_source version (hashes."%{version}"),
        },
      }
  in

  let linux_headers_gen1 = mk_linux_headers "-gen1" pkgs.buildpack_deps_rootfs in
  let linux_headers = mk_linux_headers "" pkgs.system_rootfs_2 in

  let linux = {
    version | default = default_version,
    hashes | default = default_hashes,
    config_options | default = {},
    use_tinyconfig | default = false,
    name = "linux%{if use_tinyconfig then "-tiny" else ""}-%{version}",
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
        # certs/extract-cert (built for defconfig's signed-regdb / keyring
        # chain) needs OpenSSL headers + libcrypto at build time.
        pkgs.openssl,
        # depmod (from kmod) is invoked by `make modules_install` to generate
        # modules.dep/.alias so udev can autoload modules by modalias.
        pkgs.kmod,
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
            BOBR_LINUX_CONFIG_BASE = if use_tinyconfig then "tinyconfig" else "defconfig",
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
      script_config = {
        "config.fragment" =
          let base = if use_tinyconfig then tiny_config else distro_config in
          kconfig_fragment (merge_over base config_options),
      },
    },
    inputs = {
      script = buildscript_linux,
      source = linux_source version (hashes."%{version}"),
    },
  }
  in

  # Extract the kernel image out of the linux fs-tree into a plain object
  # (a directory holding a single `bzImage`), so tools can use it directly
  # without poking into fs-files by hash.
  let linux_bzimage = {
    name = "linux-bzimage%{if pkgs.linux.use_tinyconfig then "-tiny" else ""}-%{pkgs.linux.version}",
    tag = "FsTreeExport",
    config = {
      copies = [
        { from = "boot/bzImage", to = "bzImage" },
      ],
    },
    inputs = {
      input = pkgs.linux,
    },
  }
  in

  # All loadable modules + depmod metadata, split out of the linux fs-tree so
  # the running system's rootfs can ship a full `/lib/modules/<release>`
  # without also pulling in `boot/`. The initrd takes only the boot-critical
  # subset (see filesystem/initrd.ncl); this is everything.
  let linux_modules = {
    name = "linux-modules-%{pkgs.linux.version}",
    tag = "TreeSubset",
    config = {
      include = [
        "usr/lib/modules/**",
      ],
    },
    inputs = {
      tree = pkgs.linux,
    },
  }
  in

  {
    include [
      linux_headers_gen1,
      linux,
      linux_headers,
      linux_bzimage,
      linux_modules,
    ],
  }
