let recipe = import "../recipe-lib.ncl" in
fun pkgs =>
  let payload_path = fun relative => {
    source = "payload",
    path = relative,
  }
  in
  let override_path = fun relative => {
    source = "overrides",
    path = relative,
  }
  in
  let replace_paths = fun entries => {
    operation = "replace",
    paths = std.array.map payload_path entries,
  }
  in
  let replace_override_path = fun relative => {
    operation = "replace",
    paths = [override_path relative],
  }
  in
  let replace_value = fun value => {
    operation = "replace",
    values = [value],
  }
  in

  # The runner is an ordinary bundled script. Its public top-level entry is a
  # launcher symlink like every other HostBundle command; the physical file is
  # deliberately left untouched in root/usr/bin.
  let runner_plain = {
    name = "host-bundle-qemu-runner-plain",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          {
            type = "file",
            path = "usr/bin/bobr-run-qemu",
            text = import "qemu/bobr-run-qemu.sh" as 'Text,
            executable = true,
          },
        ],
      },
    },
    inputs = {},
  }
  in
  let runner_package = {
    name = "host-bundle-qemu-runner",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [recipe.install.fs_tree_root_default_rule],
      },
    },
    inputs = {
      input = runner_plain,
    },
  }
  in

  let payload = {
    name = "host-bundle-qemu-payload",
    tag = "RootfsClosure",
    config = {},
    inputs = {
      qemu = pkgs.qemu,
      runner = runner_package,
      bash = pkgs.bash,
      coreutils = pkgs.coreutils,
      e2fsprogs = pkgs.e2fsprogs,
    },
  }
  in

  # Boot files are data of this concrete bundle, not part of the immutable
  # payload root. Compose them into an ordinary directory object and let the
  # HostBundle builder copy that object verbatim to top-level overrides/.
  let overrides_rootfs = {
    name = "host-bundle-qemu-overrides-build-rootfs",
    tag = "RootfsClosure",
    config = {},
    inputs = {
      bash = pkgs.bash,
      coreutils = pkgs.coreutils,
    },
  }
  in
  let overrides_object = {
    name = "host-bundle-qemu-overrides",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "compose_boot_artifacts",
          run_as = "root",
          cwd = "@{out}",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              install -Dm644 "@{rootfs_image}/erofs-rootfs.erofs" qemu/rootfs.erofs
              install -Dm644 "@{kernel}/bzImage" qemu/bzImage
              install -Dm644 "@{initrd}/initramfs.img" qemu/initramfs.img
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = overrides_rootfs,
      rootfs_image = pkgs.qemu_image,
      kernel = pkgs.linux_bzimage,
      initrd = pkgs.initrd,
    },
  }
  in

  let graphics_environment = {
    LIBGL_DRIVERS_PATH = replace_paths ["usr/lib"],
    GBM_BACKENDS_PATH = replace_paths ["usr/lib/gbm"],
    LIBDECOR_PLUGIN_DIR = replace_paths ["usr/lib/libdecor/plugins-1"],
    __EGL_VENDOR_LIBRARY_FILENAMES =
      replace_paths ["usr/share/glvnd/egl_vendor.d/50_mesa.json"],
    VK_DRIVER_FILES =
      replace_paths [
        "usr/share/vulkan/icd.d/intel_icd.x86_64.json",
        "usr/share/vulkan/icd.d/intel_hasvk_icd.x86_64.json",
        "usr/share/vulkan/icd.d/lvp_icd.x86_64.json",
        "usr/share/vulkan/icd.d/nouveau_icd.x86_64.json",
        "usr/share/vulkan/icd.d/radeon_icd.x86_64.json",
      ],
    SDL_VIDEODRIVER = replace_value "wayland",
  }
  in
  let host_bundle_qemu = {
    name = "host-bundle-qemu",
    tag = "HostBundle",
    config = {
      arch = "x86_64",
      policy = "strict",
      library_dirs = [
        "usr/lib64",
        "usr/lib",
      ],
      public_tools = {
        "qemu-system-x86_64" = {
          path = "usr/bin/qemu-system-x86_64",
          argument_prefix = [
            { value = "-L" },
            payload_path "usr/share/qemu",
          ],
          environment = graphics_environment,
        },
        "qemu-img" = {
          path = "usr/bin/qemu-img",
        },
        "bobr-run-qemu" = {
          path = "usr/bin/bobr-run-qemu",
          environment = {
            BOBR_QEMU_ROOTFS = replace_override_path "qemu/rootfs.erofs",
            BOBR_QEMU_KERNEL = replace_override_path "qemu/bzImage",
            BOBR_QEMU_INITRD = replace_override_path "qemu/initramfs.img",
          },
        },
      },
      internal_tools = {
        bash = {
          path = "usr/bin/bash",
        },
        rm = {
          path = "usr/bin/rm",
        },
        truncate = {
          path = "usr/bin/truncate",
        },
        "mkfs.ext4" = {
          path = "usr/bin/mkfs.ext4",
        },
      },
      environment = {},
    },
    inputs = {
      _root = payload,
      _launcher = pkgs.bobr_bundle_launcher_host_x86_64,
      overrides = overrides_object,
    },
  }
  in

  let smoke_script = {
    name = "host-bundle-qemu-smoke-script",
    tag = "Source",
    object_hash = import "host-bundle-qemu-smoke.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "host-bundles/host-bundle-qemu-smoke.sh",
    },
  }
  in
  let test_host_bundle_qemu = {
    name = "test-host-bundle-qemu",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "qemu_smoke",
          run_as = "root",
          cwd = "@{out}",
          argv = [
            "@{script}",
            "@{bundle}",
          ],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      script = smoke_script,
      bundle = host_bundle_qemu,
    },
  }
  in

  {
    include [
      host_bundle_qemu,
      test_host_bundle_qemu,
    ],
  }
