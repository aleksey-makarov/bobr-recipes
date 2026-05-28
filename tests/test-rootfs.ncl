let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_rootfs_script_source = {
    name = "test-rootfs-script-source",
    tag = "Source",
    object_hash = import "test-rootfs.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "tests/test-rootfs.sh",
    },
  }
  in

  let test_system_rootfs_0 = {
    name = "test-system-rootfs-0",
    tag = "SandboxBuildRootfs",
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
    tag = "SandboxBuildRootfs",
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
    tag = "SandboxBuildRootfs",
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

  let test_rootfs = {
    name = "test-rootfs",
    tag = "SandboxBuildRootfs",
    config = {
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
      rootfs = pkgs.rootfs,
      script = test_rootfs_script_source,
    },
  }
  in

  {
    include [
      test_system_rootfs_0,
      test_system_rootfs_1,
      test_system_rootfs_2,
      test_rootfs,
    ],
  }
