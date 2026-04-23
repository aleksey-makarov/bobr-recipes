let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_reports = {
    name = "buildscript-test-reports",
    tag = "Text",
    config = {
      executable = true,
      source = import "test-reports.sh" as 'Text,
    },
    inputs = {},
  }
  in

  let test_reports_script_source = {
    name = "test-reports-script-source",
    tag = "Source",
    object_hash = "5a8396328664cf4ba92281e288034cb8243acd7cc9fc98b1e143194f5a883129",
    origin = {
      type = "path",
      path = "/home/amakarov/home/mbuild/mbuild-recipes/tests/test-reports.sh",
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
      image = pkgs.host_image,
      script = buildscript_test_reports,
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
