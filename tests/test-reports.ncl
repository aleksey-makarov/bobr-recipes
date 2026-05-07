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
    tag = "Binary",
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
      image = pkgs.buildpack_deps_image,
      script = test_reports_script_source,
      report000 = pkgs.test_system_image_0,
      report001 = pkgs.test_system_image_1,
      report002 = pkgs.test_system_image_2,
      report003 = pkgs.test_system_image,
    },
  }
  in

  {
    include [test_reports, test_reports_script_source],
  }
