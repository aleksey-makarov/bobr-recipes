# ICU4C (International Components for Unicode) -- the i18n library mozjs links
# for the ECMAScript `Intl` API (collation, date/number formatting, locale data,
# etc.). Built as a system library so mozjs can use --with-system-icu instead of
# its bundled copy; a runtime dependency of mozjs (and thus of gjs/gnome-shell).
#
# Plain autotools, but the sources live in the tarball's `source/` subdir, and
# the release naming needs two forms of the version: `77-1` in the git tag and
# `77_1` in the filename. `version`/`source_object_hash` are node fields
# (overridable), as in linux.ncl.
let dash = fun v => std.string.replace "." "-" v in
let under = fun v => std.string.replace "." "_" v in

fun pkgs =>
  let icu_src = fun version =>
    fun hash =>
      {
        name = "icu-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/unicode-org/icu/releases/download/release-%{dash version}/icu4c-%{under version}-src.tgz",
        },
      }
  in

  let icu = {
    version | default = "77.1",
    source_object_hash
      | default
      = "588e431f77327c39031ffbb8843c0e3bc122c211374485fa87dc5f3faff24061",
    name = "icu-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        # ICU is C++, so libicu*.so link libstdc++/libgcc_s.
        pkgs.gcc_libs,
      ],
    },
    config = {
      source_subdir = "source",
      configure_args = [
        "--disable-static",
        "--enable-shared",
        "--disable-samples",
        "--disable-tests",
      ],
    },
    inputs = {
      source = icu_src version source_object_hash,
    },
  }
  in

  {
    include [
      icu,
    ],
  }
