let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_image = {
    name = "buildscript-test-image",
    tag = "Text",
    config = {
      executable = true,
      source = import "test-image.sh" as 'Text,
    },
    inputs = {},
  }
  in

  let test_system_image_0 = {
    name = "test-system-image-0",
    tag = "Binary",
    config = {
      script_config = {
        check_live_usr = "true",
        name = "system-image-0",
      },
      steps = [
        {
          name = "check_image",
          run_as = "root",
          cwd = "${out}",
          argv = ["${script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_0,
      script = buildscript_test_image,
    },
  }
  in

  let test_system_image_1 = {
    name = "test-system-image-1",
    tag = "Binary",
    config = {
      script_config = {
        name = "system-image-1",
      },
      steps = [
        {
          name = "check_image",
          run_as = "root",
          cwd = "${out}",
          argv = ["${script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_1,
      script = buildscript_test_image,
    },
  }
  in

  let test_system_image_2 = {
    name = "test-system-image-2",
    tag = "Binary",
    config = {
      script_config = {
        name = "system-image-2",
        check_live_usr = "true",
      },
      steps = [
        {
          name = "check_image",
          run_as = "root",
          cwd = "${out}",
          argv = ["${script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      script = buildscript_test_image,
    },
  }
  in

  let test_system_image = {
    name = "test-system-image",
    tag = "Binary",
    config = {
      script_config = {
        name = "system-image",
        check_python = "true",
      },
      steps = [
        {
          name = "check_image",
          run_as = "root",
          cwd = "${out}",
          argv = ["${script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image,
      script = buildscript_test_image,
    },
  }
  in

  {
    include [
      test_system_image_0,
      test_system_image_1,
      test_system_image_2,
      test_system_image,
    ],
  }
