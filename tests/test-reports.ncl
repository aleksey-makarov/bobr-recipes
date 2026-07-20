let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_reports_script_source = {
    name = "test-reports-script-source",
    tag = "Source",
    object_hash = import "test-reports.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "tests/test-reports.sh",
    },
  }
  in

  let test_reports = {
    name = "test-reports",
    tag = "Sandbox",
    config = {
      # The collected reports are plain files; capture as a plain-object
      # directory rather than an ownership-aware fs-tree.
      preserve_ownership = false,
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
      _rootfs = pkgs.buildpack_deps_rootfs,
      script = test_reports_script_source,
      report000 = pkgs.test_system_rootfs_0,
      report001 = pkgs.test_system_rootfs_1,
      report002 = pkgs.test_rootfs,
      report003 = pkgs.test_gnome_rootfs,
    },
  }
  in

  {
    include [test_reports, test_reports_script_source],
  }
