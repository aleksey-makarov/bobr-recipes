let recipe = import "recipe-lib.ncl" in

# tzdata -- the IANA time-zone database compiled into /usr/share/zoneinfo. glibc
# ships no zone data, so without this apps that resolve a *named* zone (the
# evolution-data-server calendar, ICU) get a NULL zone. Built from the IANA
# `tzcode` (for the `zic` compiler) plus the matching `tzdata` (the zone source
# files); a single zic run compiles the standard region files so that the
# aliases in `backward` resolve. Only the zoneinfo tree is kept.
# `version`/`*_object_hash` are node fields (overridable).
fun pkgs =>
  let tzcode_src = fun version =>
    fun hash =>
      {
        name = "tzcode-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://data.iana.org/time-zones/releases/tzcode%{version}.tar.gz",
        },
      }
  in

  let tzdata_src = fun version =>
    fun hash =>
      {
        name = "tzdata-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://data.iana.org/time-zones/releases/tzdata%{version}.tar.gz",
        },
      }
  in

  let tzdata = {
    version | default = "2026c",
    code_object_hash
      | default
      = "b1cffc3ace4c4c7cd0efba2f7add86ec3d0b79da48bcf03582671fd3c8feace8",
    data_object_hash
      | default
      = "e4a178a4477f3d0ea77cc31828ff72aa38feff8d61aa13e7e99e142e9d902be4",
    name = "tzdata-%{version}",
    tag = "SandboxBuild",
    deps = {
      build = [
        pkgs.linux_headers,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.make,
        pkgs.coreutils,
        pkgs.gawk,
        pkgs.sed,
        pkgs.grep,
        pkgs.findutils,
      ],
      runtime = [],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "build_zoneinfo",
          run_as = "root",
          cwd = "@{build}/source",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              # tzcode is unpacked in the source dir; add the zone data files.
              tar -xf "$TZDATA_TARBALL"

              # Build just the zic compiler (no gettext in this toolchain).
              make CC=gcc CFLAGS="-O2 -DHAVE_GETTEXT=0" zic

              install -d "$OUT/usr/share/zoneinfo"
              # One zic invocation so Links in `backward` resolve against zones
              # defined by the region files in the same run. `-b fat` keeps the
              # 32/64-bit compatible format.
              ./zic -b fat -d "$OUT/usr/share/zoneinfo" \
                etcetera southamerica northamerica europe africa \
                antarctica asia australasia backward factory

              # The zone tables are needed by consumers that enumerate zones
              # rather than open a TZif by path -- notably libical (built against
              # system tzdata), which parses zone.tab to populate its builtin
              # zone list; without it every zone lookup returns NULL.
              install -m644 zone.tab zone1970.tab iso3166.tab leapseconds \
                "$OUT/usr/share/zoneinfo/"
            "%,
          ],
          env = {
            OUT = "@{out}",
            TZDATA_TARBALL = "@{tzdata}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      source = tzcode_src version code_object_hash,
      tzdata = tzdata_src version data_object_hash,
    },
  }
  in

  { include [ tzdata ] }
