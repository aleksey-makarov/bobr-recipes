let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_rootfs_script_source = {
    name = "test-rootfs-script-source",
    tag = "Source",
    object_hash = import "test-rootfs.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/test-rootfs.sh",
    },
  }
  in

  let test_rootfs = {
    name = "test-rootfs",
    tag = "Sandbox",
    config = {
      # The `Sandbox` tag captures the output as a plain-object directory, so
      # the report collector can read the plain report files directly via a
      # non-`_` input.
      script_config = {
        name = "rootfs",
        check_python = "true",
      },
      steps = [
        {
          name = "check_image",
          run_as = "root",
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.rootfs,
      script = test_rootfs_script_source,
    },
  }
  in

  let test_gnome_rootfs = {
    name = "test-gnome-rootfs",
    tag = "Sandbox",
    config = {
      # The `Sandbox` tag captures the output as a plain-object directory, so
      # the report collector can read the plain report files directly via a
      # non-`_` input.
      script_config = {
        name = "gnome-rootfs",
        check_python = "true",
        check_graphics = "true",
        check_gnome = "true",
        # gnome-shell's JS references these GI namespaces, but they are only
        # loaded behind compile-time flags we built without (NetworkManager,
        # bluetooth) or a runtime try/catch (Malcontent parental controls), so a
        # missing typelib is harmless -- reported as INFO, not a failure. The
        # unconditionally-required imports (Geoclue, GWeather, Rsvg) are NOT
        # listed here: their typelibs must be present or the shell crashes at
        # startup (misc/dependencies.js). Everything else must have a typelib.
        gnome_optional_typelibs = "GnomeBluetooth Malcontent",
      },
      steps = [
        {
          name = "check_image",
          run_as = "root",
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      _rootfs = pkgs.gnome_rootfs,
      script = test_rootfs_script_source,
    },
  }
  in

  {
    include [
      test_rootfs,
      test_gnome_rootfs,
    ],
  }
