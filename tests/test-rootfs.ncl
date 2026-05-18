let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_rootfs_script_source = {
    name = "test-rootfs-script-source",
    tag = "Source",
    object_hash = import "test-rootfs.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "tests/test-rootfs.sh",
      mode = "direct",
    },
  }
  in

  let test_system_rootfs_0 = {
    name = "test-system-rootfs-0",
    tag = "Sandbox",
    config = {
      script_config = {
        name = "system-rootfs-0",
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
      rootfs = pkgs.system_rootfs_0,
      script = test_rootfs_script_source,
    },
  }
  in

  let test_system_rootfs_1 = {
    name = "test-system-rootfs-1",
    tag = "Sandbox",
    config = {
      script_config = {
        name = "system-rootfs-1",
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
      rootfs = pkgs.system_rootfs_1,
      script = test_rootfs_script_source,
    },
  }
  in

  let test_system_rootfs_2 = {
    name = "test-system-rootfs-2",
    tag = "Sandbox",
    config = {
      script_config = {
        name = "system-rootfs-2",
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
      rootfs = pkgs.system_rootfs_2,
      script = test_rootfs_script_source,
    },
  }
  in

  let test_system_rootfs = {
    name = "test-system-rootfs",
    tag = "Sandbox",
    config = {
      script_config = {
        name = "system-rootfs",
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
      rootfs = pkgs.system_rootfs,
      script = test_rootfs_script_source,
    },
  }
  in

  let test_qemu_rootfs = {
    name = "test-qemu-rootfs",
    tag = "Sandbox",
    config = {
      script_config = {
        name = "qemu-rootfs",
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
      rootfs = pkgs.qemu_rootfs,
      script = test_rootfs_script_source,
    },
  }
  in

  {
    include [
      test_system_rootfs_0,
      test_system_rootfs_1,
      test_system_rootfs_2,
      test_system_rootfs,
      test_qemu_rootfs,
    ],
  }
