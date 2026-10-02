# bobr-bundle-launcher is built from its published source crate rather than a
# prebuilt bobr release asset. Cargo.lock supplies the complete immutable
# dependency set consumed by the generic offline Cargo builder.

fun pkgs =>
  let mk_src = fun version => fun hash => {
    name = "bobr-bundle-launcher-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://static.crates.io/crates/bobr-bundle-launcher/bobr-bundle-launcher-%{version}.crate",
    },
  }
  in

  let bobr_bundle_launcher = {
    version | default = "0.1.10",
    source_object_hash
      | default
      = "f75f78790ec03db607606ccc64d2ff3805eddad721dd631d7a32b3e83227713a",
    cargo_lock | default = import "Cargo.lock" as 'Toml,
    name = "bobr-bundle-launcher-%{version}",
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      bobr_bundle_launcher,
    ],
  }
