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

  let common_overrides = {
    name = "host-bundle-common-overrides-source",
    tag = "Source",
    object_hash =
      import "host-bundle-common-overrides.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "host-bundles/host-bundle-common-overrides",
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
      fonts = pkgs.dejavu,
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
  let mk_overrides = fun bundle_name => fun rootfs_image_node => {
    name = "%{bundle_name}-overrides",
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
              install -Dm644 \
                "@{fontconfig_overrides}/fontconfig/fonts.conf" \
                fontconfig/fonts.conf
            "%,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = overrides_rootfs,
      rootfs_image = rootfs_image_node,
      kernel = pkgs.linux_bzimage,
      initrd = pkgs.initrd,
      fontconfig_overrides = common_overrides,
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
    XLOCALEDIR = replace_paths ["usr/share/X11/locale"],
    FONTCONFIG_FILE = replace_override_path "fontconfig/fonts.conf",
    SDL_VIDEODRIVER = replace_value "wayland",
  }
  in
  let mk_host_bundle = fun args => {
    name = args.bundle_name,
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
          environment = graphics_environment & {
            # virglrenderer starts the Venus render server out of process.
            # Its patched explicit override uses PATH, whose first directory
            # is HostBundle's managed internal-wrapper directory.
            RENDER_SERVER_EXEC_PATH = replace_value "virgl_render_server",
          },
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
            BOBR_QEMU_VARIANT = replace_value args.variant,
            BOBR_QEMU_GRAPHICAL = replace_value args.graphical,
            BOBR_QEMU_DEFAULT_MEMORY_MIB = replace_value args.memory_mib,
            BOBR_QEMU_DEFAULT_HOME_IMAGE = replace_value args.home_image,
            BOBR_QEMU_DEFAULT_DIAG_SOCK = replace_value args.diag_sock,
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
        "fc-match" = {
          path = "usr/bin/fc-match",
          environment = {
            FONTCONFIG_FILE = replace_override_path "fontconfig/fonts.conf",
          },
        },
        virgl_render_server = {
          path = "usr/libexec/virgl_render_server",
        },
      },
      environment = {},
    },
    inputs = {
      _root = payload,
      _launcher = pkgs.bobr_bundle_launcher_host_x86_64,
      overrides = mk_overrides args.bundle_name args.rootfs_image,
    },
  }
  in

  let plain_args = {
    bundle_name = "host-bundle-qemu",
    variant = "plain",
    graphical = "0",
    memory_mib = "1024",
    home_image = "home.img",
    diag_sock = "diag.sock",
    rootfs_image = pkgs.qemu_image,
  }
  in
  let weston_args = {
    bundle_name = "host-bundle-qemu-weston",
    variant = "weston",
    graphical = "1",
    memory_mib = "4096",
    home_image = "home-weston.img",
    diag_sock = "diag-weston.sock",
    rootfs_image = pkgs.qemu_weston_image,
  }
  in
  let gnome_args = {
    bundle_name = "host-bundle-qemu-gnome",
    variant = "gnome",
    graphical = "1",
    memory_mib = "4096",
    home_image = "home-gnome.img",
    diag_sock = "diag-gnome.sock",
    rootfs_image = pkgs.qemu_gnome_image,
  }
  in

  let host_bundle_qemu = mk_host_bundle plain_args in
  let host_bundle_qemu_weston = mk_host_bundle weston_args in
  let host_bundle_qemu_gnome = mk_host_bundle gnome_args in

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
  let mk_host_bundle_test = fun args => fun bundle_node => {
    name = "test-%{args.bundle_name}",
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
            args.variant,
            args.graphical,
            args.memory_mib,
            args.home_image,
            args.diag_sock,
          ],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      script = smoke_script,
      bundle = bundle_node,
    },
  }
  in

  let test_host_bundle_qemu =
    mk_host_bundle_test plain_args host_bundle_qemu
  in
  let test_host_bundle_qemu_weston =
    mk_host_bundle_test weston_args host_bundle_qemu_weston
  in
  let test_host_bundle_qemu_gnome =
    mk_host_bundle_test gnome_args host_bundle_qemu_gnome
  in

  {
    include [
      host_bundle_qemu,
      host_bundle_qemu_weston,
      host_bundle_qemu_gnome,
      test_host_bundle_qemu,
      test_host_bundle_qemu_weston,
      test_host_bundle_qemu_gnome,
    ],
  }
