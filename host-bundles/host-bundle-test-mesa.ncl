fun pkgs =>
  let payload_path = fun relative => {
    source = "payload",
    path = relative,
  }
  in
  let replace_paths = fun entries => {
    operation = "replace",
    paths = std.array.map payload_path entries,
  }
  in
  let replace_value = fun value => {
    operation = "replace",
    values = [value],
  }
  in
  let override_path = fun relative => {
    source = "overrides",
    path = relative,
  }
  in
  let replace_override_paths = fun entries => {
    operation = "replace",
    paths = std.array.map override_path entries,
  }
  in
  let software_opengl_environment = {
    LIBGL_ALWAYS_SOFTWARE = replace_value "true",
    GALLIUM_DRIVER = replace_value "llvmpipe",
  }
  in

  let host_bundle_test_mesa_payload = {
    name = "host-bundle-test-mesa-payload",
    tag = "RootfsClosure",
    config = {},
    inputs = {
      mesa = pkgs.mesa,
      mesa_demos = pkgs.mesa_demos,
      glmark2 = pkgs.glmark2,
      vulkan_tools = pkgs.vulkan_tools,
      kmscube = pkgs.kmscube,
      fonts = pkgs.dejavu,
      locales = pkgs.glibc_locales,
    },
  }
  in

  let overrides_source = {
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

  let host_bundle_test_mesa = {
    name = "host-bundle-test-mesa",
    tag = "HostBundle",
    config = {
      arch = "x86_64",
      policy = "strict",
      library_dirs = [
        "usr/lib64",
        "usr/lib",
      ],
      public_tools = {
        eglinfo = {
          path = "usr/bin/eglinfo",
        },
        "eglinfo-software" = {
          path = "usr/bin/eglinfo",
          argv0 = "eglinfo",
          environment = software_opengl_environment,
        },
        gears = {
          path = "usr/bin/eglgears_wayland",
          argv0 = "eglgears_wayland",
        },
        vulkaninfo = {
          path = "usr/bin/vulkaninfo",
        },
        "vulkaninfo-software" = {
          path = "usr/bin/vulkaninfo",
          argv0 = "vulkaninfo",
          environment = {
            VK_DRIVER_FILES =
              replace_paths [
                "usr/share/vulkan/icd.d/lvp_icd.x86_64.json",
              ],
          },
        },
        vkcube = {
          path = "usr/bin/vkcube",
        },
        "vkcube-software" = {
          path = "usr/bin/vkcube",
          argv0 = "vkcube",
          environment = {
            VK_DRIVER_FILES =
              replace_paths [
                "usr/share/vulkan/icd.d/lvp_icd.x86_64.json",
              ],
          },
        },
        "glmark2-wayland" = {
          path = "usr/bin/glmark2-wayland",
        },
        "glmark2-software" = {
          path = "usr/bin/glmark2-wayland",
          argv0 = "glmark2-wayland",
          environment = software_opengl_environment,
        },
        "glmark2-es2-wayland" = {
          path = "usr/bin/glmark2-es2-wayland",
        },
        "glmark2-es2-software" = {
          path = "usr/bin/glmark2-es2-wayland",
          argv0 = "glmark2-es2-wayland",
          environment = software_opengl_environment,
        },
        kmscube = {
          path = "usr/bin/kmscube",
        },
      },
      internal_tools = {
        "fc-match" = {
          path = "usr/bin/fc-match",
        },
      },
      environment = {
        LOCALE_ARCHIVE =
          replace_paths [
            "usr/lib/locale/locale-archive",
          ],
        LIBGL_DRIVERS_PATH =
          replace_paths [
            "usr/lib",
          ],
        GBM_BACKENDS_PATH =
          replace_paths [
            "usr/lib/gbm",
          ],
        LIBDECOR_PLUGIN_DIR =
          replace_paths [
            "usr/lib/libdecor/plugins-1",
          ],
        FONTCONFIG_FILE =
          replace_override_paths [
            "fontconfig/fonts.conf",
          ],
        __EGL_VENDOR_LIBRARY_FILENAMES =
          replace_paths [
            "usr/share/glvnd/egl_vendor.d/50_mesa.json",
          ],
        VK_DRIVER_FILES =
          replace_paths [
            "usr/share/vulkan/icd.d/intel_icd.x86_64.json",
            "usr/share/vulkan/icd.d/intel_hasvk_icd.x86_64.json",
            "usr/share/vulkan/icd.d/lvp_icd.x86_64.json",
            "usr/share/vulkan/icd.d/nouveau_icd.x86_64.json",
            "usr/share/vulkan/icd.d/radeon_icd.x86_64.json",
          ],
        GLMARK2_DATA_PATH =
          replace_paths [
            "usr/share/glmark2",
          ],
      },
    },
    inputs = {
      _root = host_bundle_test_mesa_payload,
      _launcher = pkgs.bobr_bundle_launcher_host_x86_64,
      overrides = overrides_source,
    },
  }
  in

  let smoke_script = {
    name = "host-bundle-test-mesa-smoke-script",
    tag = "Source",
    object_hash =
      import "host-bundle-test-mesa-smoke.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "host-bundles/host-bundle-test-mesa-smoke.sh",
    },
  }
  in

  let test_host_bundle_test_mesa = {
    name = "test-host-bundle-test-mesa",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "software_smoke",
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
      bundle = host_bundle_test_mesa,
    },
  }
  in

  {
    include [
      host_bundle_test_mesa,
      test_host_bundle_test_mesa,
    ],
  }
