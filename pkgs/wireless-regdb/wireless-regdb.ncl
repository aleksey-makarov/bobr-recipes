let recipe = import "../../recipe-lib.ncl" in

fun pkgs =>
  let wireless_regdb_src = fun version => fun hash => {
    name = "wireless-regdb-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://mirrors.edge.kernel.org/pub/software/network/wireless-regdb/wireless-regdb-%{version}.tar.xz",
        "https://mirrors.kernel.org/pub/software/network/wireless-regdb/wireless-regdb-%{version}.tar.xz",
      ],
    },
  }
  in

  let buildscript_wireless_regdb = {
    name = "buildscript-wireless-regdb",
    tag = "Source",
    object_hash = import "wireless-regdb-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/wireless-regdb/wireless-regdb-build.sh",
    },
  }
  in

  # The wireless regulatory database: which frequencies, bandwidths and transmit
  # powers are permitted in each country. cfg80211 loads it from
  # /lib/firmware/regulatory.db at init; without it the stack falls back to the
  # built-in world domain, the most restrictive one there is, so a real machine
  # would come up with its Wi-Fi needlessly crippled. Pure data -- versions are
  # release dates, and a new one means the rules changed somewhere.
  let wireless_regdb = {
    version | default = "2026.05.30",
    source_object_hash
      | default
      = "8a27bfc081bafed8c24dd70fab0d96f098e5a0bfcd08d3da672595f225ab8993",
    name = "wireless-regdb-%{version}",
    tag = "SandboxInstallDeps",
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
            BOBR_INSTALL_DIR = "/",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_wireless_regdb,
      source = wireless_regdb_src version source_object_hash,
    },
  }
  in

  {
    include [
      wireless_regdb,
    ],
  }
