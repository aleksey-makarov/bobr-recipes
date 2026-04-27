let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let test_image_script_source = {
    name = "test-image-script-source",
    tag = "Source",
    object_hash = import "test-image.sh.fsobj-hash" as 'Text,
    origin = {
      type = "path",
      path = "tests/test-image.sh",
      mode = "direct",
    },
    meta = {},
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
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_0,
      script = test_image_script_source,
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
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_1,
      script = test_image_script_source,
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
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      script = test_image_script_source,
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
          cwd = "@{out}",
          argv = ["@{script}"],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image,
      script = test_image_script_source,
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
