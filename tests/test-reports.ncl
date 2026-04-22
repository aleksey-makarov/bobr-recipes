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
    include [test_reports],
  }
