let recipe = import "recipe-lib.ncl" in
let version = "2.0.7" in

fun pkgs =>
  let bibata_cursors_src = {
    name = "bibata-cursors-src-%{version}",
    tag = "Source",
    object_hash = "6cb0a3bf308ee17a33ff06e4547a31c86913ff51e1730e7b95b951bf19459ea5",
    origin = {
      tag = "Http",
      url = "https://github.com/ful1e5/Bibata_Cursor/releases/download/v%{version}/Bibata-Modern-Classic.tar.xz",
    },
  }
  in

  let buildscript_bibata_cursors = {
    name = "buildscript-bibata-cursors",
    tag = "Source",
    object_hash = import "bibata-cursors-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "bibata-cursors-build.sh",
    },
  }
  in

  # Prebuilt XCursor theme (no build tooling needed), installed as the system
  # default cursor theme so Weston/desktop clients find a complete cursor set
  # (dnd-move/copy/none etc.) instead of warning about missing cursors.
  let bibata_cursors = {
    name = "bibata-cursors-%{version}",
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
      script = buildscript_bibata_cursors,
      source = bibata_cursors_src,
    },
  }
  in

  {
    include [
      buildscript_bibata_cursors,
      bibata_cursors,
    ],
  }
