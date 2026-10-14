let recipe = import "../../recipe-lib.ncl" in
# glycin -- image loading library. mutter links only libglycin (`glycin-2`), so
# the runtime loaders (heif/jxl/raw/svg -- heavy codecs), the GTK 4 bindings,
# the thumbnailer, introspection and tests are all off. Only the C library is
# built.
#
# glycin is a Rust (Cargo workspace) project driven by Meson; its crates are
# vendored offline via `cargo.ncl` + the `Bundle` builder. The public source and
# vendored-crates recipes are a coupled pair: a version update must replace both
# so the offline dependency set matches the Cargo.lock shipped by the selected
# source.
let cargo = import "../../cargo.ncl" in

let series = recipe.version_prefix 2 in

fun pkgs =>
  let matching_version = cargo.matching_version "glycin" in

  let glycin_src = {
    version | default = "2.1.5",
    name = "glycin-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "6c09757ee906330a60b6705753aa56bca007ad219b95e6e3537510d41bc341c8",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/glycin/%{series version}/glycin-%{version}.tar.xz",
    },
  }
  in

  let glycin_crates = {
    version | default = "2.1.5",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "glycin-crates-%{version}",
    tag = "Bundle",
    config = {},
    inputs = cargo.vendor_inputs cargo_lock,
  }
  in

  # Unpack each bundled `.crate` into a cargo `vendor/` tree and point cargo at
  # it offline. Runs before `meson setup`; cargo (invoked by meson from
  # `$BOBR_BUILD_DIR/build`) discovers `$BOBR_BUILD_DIR/.cargo/config.toml` by
  # walking up from its working directory.
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

  let glycin = {
    name = "glycin-%{matching_version inputs.source.version inputs.crates.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.fontconfig,
        pkgs.lcms2,
        pkgs.libseccomp,
        pkgs.rust_bin,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.fontconfig,
        pkgs.lcms2,
        pkgs.libseccomp,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dprofile=release",
        "-Dlto=false",
        "-Dlibglycin=true",
        "-Dlibglycin-gtk4=false",
        "-Dglycin-loaders=false",
        "-Dglycin-thumbnailer=false",
        "-Dintrospection=false",
        "-Dvapi=false",
        "-Dtests=false",
        "-Dcapi_docs=false",
        "-Dpython_tests=false",
      ],
      pre_configure = [vendor_crates_step, cargo.verify_lock_step],
    },
    inputs = {
      source = pkgs.glycin_src,
      crates = pkgs.glycin_crates,
    },
  }
  in

  {
    include [
      glycin_src,
      glycin_crates,
      glycin,
    ],
  }
