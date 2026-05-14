let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_reports_script_source = {
    name = "test-reports-script-source",
    tag = "Source",
    object_hash = import "test-reports.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "tests/test-reports.sh",
      mode = "direct",
    },
    meta = {},
  }
  in

  let test_reports = {
    name = "test-reports",
    tag = "Sandbox",
    config = {
      steps = [
        {
          name = "collect_reports",
          run_as = "root",
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs,
      script = test_reports_script_source,
      report000 = pkgs.test_system_rootfs_0,
      report001 = pkgs.test_system_rootfs_1,
      report002 = pkgs.test_system_rootfs_2,
      report003 = pkgs.test_system_rootfs,
      report004 = pkgs.test_qemu_rootfs,
    },
  }
  in

  {
    include [test_reports, test_reports_script_source],
  }
