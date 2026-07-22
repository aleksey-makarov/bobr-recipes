let recipe = import "../recipe-lib.ncl" in
let br = import "../build-rootfs.ncl" in

# The source release. `version` picks the kernel version and
# `source_object_hash` is its source tarball hash; both are node fields, so an
# overlay builds a different kernel by overriding them:
#   linux = prev.linux & {
#     version = "6.19.1",
#     source_object_hash = "<sha256>",
#   }

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
let config_distro = import "config-distro.ncl" in
let config_tiny = import "config-tiny.ncl" in

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
        # Install into a virgin /stage: the UAPI headers overlap the build rootfs
        # (buildpack / system_rootfs_2 already carry kernel headers), so an
        # additive install to the real /usr/include would be rejected. The
        # SandboxStageRootfs lowering re-roots /stage -> / via TreeMove.
        BOBR_INSTALL_DIR = "/stage",
      }
      in
      {
        version | default = "6.18.38",
        source_object_hash | default = "ac26e508abd56e9f8b89872b6e10c49fc823bcc70d8068a5d8504c1a7c4ff045",
        name = "linux-headers%{variant}-%{version}",
        tag = "SandboxStageRootfs",
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
          source = linux_source version source_object_hash,
        },
      }
  in

  let linux_headers_gen1 = mk_linux_headers "-gen1" pkgs.buildpack_deps_rootfs in
  # Plain headers build in a deps-derived closure (no system_rootfs_2): the
  # native toolchain plus the gen1 kernel headers. The gen1 headers are needed
  # to compile the build's host tools (glibc's <bits/errno.h> pulls in
  # <linux/errno.h>); using gen1 rather than this package's own output avoids a
  # cycle. Installing into /stage (SandboxStageRootfs) then keeps clear of the
  # gen1 headers already at /usr/include.
  let linux_headers =
    mk_linux_headers
      ""
      (
        br.build_rootfs_closure
          pkgs
          "linux-headers-build-rootfs"
          (br.native_toolchain_deps pkgs @ [pkgs.linux_headers_gen1])
      )
  in

  # Shared across all three build steps (configure adds BOBR_LINUX_CONFIG_BASE),
  # mirroring `headers_env` in mk_linux_headers above.
  let full_env = {
    BOBR_LINUX_BUILD_KIND = "full",
    BOBR_SOURCE_DIR = "@{build}/source",
    BOBR_INSTALL_DIR = "/",
  }
  in

  let linux = {
    version | default = "6.18.38",
    source_object_hash | default = "ac26e508abd56e9f8b89872b6e10c49fc823bcc70d8068a5d8504c1a7c4ff045",
    config_options | default = {},
    use_tinyconfig | default = false,
    name = "linux%{if use_tinyconfig then "-tiny" else ""}-%{version}",
    tag = "SandboxInstallBuild",
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
          env = full_env & { BOBR_LINUX_CONFIG_BASE = if use_tinyconfig then "tinyconfig" else "defconfig" },
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = full_env,
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = full_env,
        },
      ],
      script_config = {
        "config.fragment" =
          let base = if use_tinyconfig then config_tiny else config_distro in
          kconfig_fragment (merge_over base config_options),
      },
    },
    inputs = {
      script = buildscript_linux,
      source = linux_source version source_object_hash,
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
