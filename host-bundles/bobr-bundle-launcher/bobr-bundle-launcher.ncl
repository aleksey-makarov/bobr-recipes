# bobr-bundle-launcher is built from its published source crate rather than a
# prebuilt bobr release asset. Cargo.lock supplies the complete immutable
# dependency set consumed by the generic offline Cargo builder.
let cargo = import "../../cargo.ncl" in
fun pkgs =>
  let matching_version = cargo.matching_version "bobr-bundle-launcher" in

  let bobr_bundle_launcher_src = {
    version | default = "0.1.10",
    name = "bobr-bundle-launcher-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "f75f78790ec03db607606ccc64d2ff3805eddad721dd631d7a32b3e83227713a",
    origin = {
      tag = "Http",
      url = "https://static.crates.io/crates/bobr-bundle-launcher/bobr-bundle-launcher-%{version}.crate",
    },
  }
  in

  let bobr_bundle_launcher_crates = {
    version | default = "0.1.10",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "bobr-bundle-launcher-%{version}-crates",
    tag = "Bundle",
    config = {},
    inputs = cargo.vendor_inputs cargo_lock,
  }
  in

  let bobr_bundle_launcher = {
    name = "bobr-bundle-launcher-%{matching_version inputs.source.version inputs.crates.version}",
    tag = "Cargo",
    config = {
      bins = ["bobr-bundle-launcher"],
      env = {
        CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl",
      },
      post_install = {
        name = "install_bundle_launcher",
        run_as = "root",
        argv = [
          "/bin/bash",
          "-ec",
          m%"
            launcher=/usr/bin/bobr-bundle-launcher
            install -d /usr/libexec
            strip "$launcher"
            mv "$launcher" /usr/libexec/bobr-bundle-launcher
            launcher=/usr/libexec/bobr-bundle-launcher

            readelf -h "$launcher" \
              | grep -Eq 'Machine:[[:space:]]+Advanced Micro Devices X86-64'
            if readelf -l "$launcher" | grep -q INTERP; then
              echo "bobr-bundle-launcher contains PT_INTERP" >&2
              exit 1
            fi
            if readelf -d "$launcher" | grep -q '(NEEDED)'; then
              echo "bobr-bundle-launcher contains DT_NEEDED" >&2
              exit 1
            fi
          "%,
        ],
      },
    },
    deps = {
      build = [
        pkgs.rust_std_native_musl,
      ],
      runtime = [],
    },
    inputs = {
      source = pkgs.bobr_bundle_launcher_src,
      crates = pkgs.bobr_bundle_launcher_crates,
    },
  }
  in

  {
    include [
      bobr_bundle_launcher_src,
      bobr_bundle_launcher_crates,
      bobr_bundle_launcher,
    ],
  }
