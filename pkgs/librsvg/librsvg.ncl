# librsvg -- SVG rendering library. gnome-shell imports its Rsvg-2.0 typelib
# unconditionally at startup (misc/dependencies.js; also used by ui/padOsd.js), so
# it is a hard dependency of the session. librsvg's core is Rust; we pin the
# 2.57.x line, which still ships the Autotools build that drives cargo directly
# (2.59+ switched to meson + the cargo-c tool we do not have). The Rsvg-2.0 API is
# stable, so this typelib satisfies gnome-shell 50. Crates are vendored offline
# via cargo.ncl + the vendor step (as glycin does); CARGO_HOME points cargo -- run
# by the Makefile from the source root -- at that offline config. Introspection is
# on (produces the typelib), the gdk-pixbuf SVG loader, Vala, docs and tests off.
#
# Like glycin, the public source and vendored-crates recipes are a coupled pair:
# a version update must replace both so the offline dependency set matches the
# Cargo.lock shipped by the selected source.
let recipe = import "../../recipe-lib.ncl" in
let cargo = import "../../cargo.ncl" in
let series = recipe.version_prefix 2 in

fun pkgs =>
  let matching_version = cargo.matching_version "librsvg" in

  let librsvg_src = {
    version | default = "2.57.1",
    name = "librsvg-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "074671a3ed6fbcd67cae2a40e539107f4f097ca8a4ab1a894c05e2524ff340ef",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/librsvg/%{series version}/librsvg-%{version}.tar.xz",
    },
  }
  in

  let librsvg_crates = {
    version | default = "2.57.1",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "librsvg-crates-%{version}",
    tag = "Bundle",
    config = {},
    inputs = cargo.vendor_inputs cargo_lock,
  }
  in

  # Unpack each vendored `.crate` into a cargo `vendor/` tree and point cargo at
  # it offline. Runs before configure; cargo is invoked by the Makefile from the
  # source root, so CARGO_HOME (set in config.env) makes it read this config.
  let vendor_crates_step = {
    name = "bobr_vendor_crates",
    run_as = "build-user",
    cwd = "@{build}",
    argv = [
      "/bin/sh",
      "-ec",
      m%%"
        vendor="$BOBR_BUILD_DIR/vendor"
        mkdir -p "$vendor"
        for crate in "@{crates}"/*; do
          tmp="$(mktemp -d)"
          tar -C "$tmp" -xf "$crate"
          top="$(ls "$tmp")"
          mv "$tmp/$top" "$vendor/$top"
          rmdir "$tmp"
          sha="$(sha256sum "$crate" | cut -d' ' -f1)"
          printf '{"files":{},"package":"%s"}' "$sha" > "$vendor/$top/.cargo-checksum.json"
        done
        mkdir -p "$BOBR_BUILD_DIR/.cargo"
        cat > "$BOBR_BUILD_DIR/.cargo/config.toml" <<EOF
        [source.crates-io]
        replace-with = "vendored-sources"

        [source.vendored-sources]
        directory = "$vendor"

        [net]
        offline = true
        EOF
      "%%,
    ],
  }
  in

  let librsvg = {
    name = "librsvg-%{matching_version inputs.source.version inputs.crates.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.rust_bin,
        pkgs.cairo,
        pkgs.gdk_pixbuf,
        pkgs.pango,
        pkgs.harfbuzz,
        pkgs.freetype,
        pkgs.glib,
        pkgs.libxml2,
        pkgs.gobject_introspection,
        # g-ir-scanner imports distutils (gone in 3.13); setuptools provides it.
        pkgs.python_setuptools,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.cairo,
        pkgs.gdk_pixbuf,
        pkgs.pango,
        pkgs.harfbuzz,
        pkgs.freetype,
        pkgs.libxml2,
      ],
    },
    config = {
      env = {
        CARGO_HOME = "@{build}/.cargo",
      },
      configure_args = [
        "--enable-introspection",
        # The GdkPixbuf SVG loader: GNOME's symbolic icons are SVG, and St/gtk
        # load them through gdk-pixbuf, so without this loader every SVG icon
        # falls back to the broken-image glyph (blank status area, generic app
        # icons). The gnome-rootfs finalize step regenerates loaders.cache.
        "--enable-pixbuf-loader",
        "--disable-vala",
        "--disable-gtk-doc",
        "--disable-static",
        "--disable-installed-tests",
        "--disable-always-build-tests",
      ],
      pre_configure = vendor_crates_step,
      # Without DESTDIR the install runs gdk-pixbuf-query-loaders and ships
      # loaders.cache. That whole-system cache must not come from a package --
      # gnome-finalize regenerates it -- so drop the freshly created copy (an
      # upper-only removal, so the layer stays additive). The SVG loader module
      # itself is still shipped.
      post_install = {
        name = "drop_pixbuf_loaders_cache",
        run_as = "root",
        argv = ["rm", "-fv", "/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"],
      },
    },
    inputs = {
      source = pkgs.librsvg_src,
      crates = pkgs.librsvg_crates,
    },
  }
  in

  {
    include [
      librsvg_src,
      librsvg_crates,
      librsvg,
    ],
  }
