# iso-codes -- ISO country/language/currency code lists + translations. A pure
# data package (XML + .mo files + iso-codes.pc); gnome-desktop needs it to
# localise language/territory names. Meson build. Upstream ships no static
# release tarball (its salsa git archive is generated on the fly and unreliable
# to fetch), so we take Debian's repackaged orig tarball from the static pool. A
# python3 script turns the JSON data into XML, and gettext builds translations.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let iso_codes_src = fun version =>
    fun hash =>
      {
        name = "iso-codes-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://deb.debian.org/debian/pool/main/i/iso-codes/iso-codes_%{version}.orig.tar.xz",
        },
      }
  in

  let iso_codes = {
    version | default = "4.20.1",
    source_object_hash
      | default
      = "5d551f3ddb32548c4321e9011720fd97751af0107592f79ebffc939bd32f2268",
    name = "iso-codes-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.python,
        pkgs.gettext,
      ],
      runtime = [],
    },
    config = {
      setup_args = [],
    },
    inputs = {
      source = iso_codes_src version source_object_hash,
    },
  }
  in

  {
    include [
      iso_codes,
    ],
  }
