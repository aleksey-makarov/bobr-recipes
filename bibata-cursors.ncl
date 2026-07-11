let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bibata_cursors_src = fun version => fun hash => {
    name = "bibata-cursors-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "2.0.7",
    source_object_hash | default = "7d3495864e5bbef02f5e77de760b2905903b63c71495a78ef6306d19a3b556d8",
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
      source = bibata_cursors_src version source_object_hash,
    },
  }
  in

  {
    include [
      buildscript_bibata_cursors,
      bibata_cursors,
    ],
  }
