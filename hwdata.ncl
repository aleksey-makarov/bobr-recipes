let recipe = import "recipe-lib.ncl" in
let version = "0.395" in

fun pkgs =>
  let hwdata_src = {
    name = "hwdata-src-%{version}",
    tag = "Source",
    object_hash = "3eba2d9d012b0f6024ca56ec2926cfc813efcbe754053182e7e162571f48f0b6",
    origin = {
      tag = "Http",
      url = "https://github.com/vcrhonek/hwdata/archive/refs/tags/v%{version}.tar.gz",
    },
  }
  in

  let buildscript_hwdata = {
    name = "buildscript-hwdata",
    tag = "Source",
    object_hash = import "hwdata-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "hwdata-build.sh",
    },
  }
  in

  # Hardware identification data (pnp.ids/pci.ids/usb.ids) + hwdata.pc.
  # Build-time only: libdisplay-info reads pnp.ids to generate its EDID vendor
  # name table. Installed via a script rather than hwdata's Makefile, which is
  # incomplete in the git archive (missing generated hwdata.spec) and only
  # needed for distro packaging anyway.
  let hwdata = {
    name = "hwdata-%{version}",
    tag = "SandboxBuild",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
      ],
      runtime = [],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            BOBR_SOURCE_DIR = "@{build}/source",
            BOBR_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_hwdata,
      source = hwdata_src,
    },
  }
  in

  {
    include [
      buildscript_hwdata,
      hwdata,
    ],
  }
