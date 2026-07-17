# glycin -- image loading library. mutter links only libglycin (`glycin-2`), so
# the runtime loaders (heif/jxl/raw/svg -- heavy codecs), the GTK 4 bindings,
# the thumbnailer, introspection and tests are all off. Only the C library is
# built.
#
# glycin is a Rust (Cargo workspace) project driven by Meson; its crates are
# vendored offline via `cargo.ncl` + the `Bundle` builder. Because a Cargo.lock
# pins one exact version, the version and its vendored crates must move together,
# so this exposes three coupled, mutually consistent overridable fields --
# `version`, `source_object_hash`, and `cargo_lock`. To move to another version,
# an overlay must override ALL THREE together (`cargo_lock = import
# "<their>/Cargo.lock" as 'Toml`); otherwise the version and the vendored crates
# would disagree.
let cargo = import "../cargo.ncl" in

let series = fun v =>
  let p = std.string.split "." v in
  "%{std.array.at 0 p}.%{std.array.at 1 p}"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "glycin-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/glycin/%{series version}/glycin-%{version}.tar.xz",
        },
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
    version | default = "2.1.5",
    source_object_hash
      | default
      = "6c09757ee906330a60b6705753aa56bca007ad219b95e6e3537510d41bc341c8",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "glycin-%{version}",
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
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      pre_configure = vendor_crates_step,
    },
    inputs = {
      source = mk_src version source_object_hash,
      crates = cargo.vendor_bundle "glycin-crates-%{version}" cargo_lock,
    },
  }
  in

  {
    include [
      glycin,
    ],
  }
