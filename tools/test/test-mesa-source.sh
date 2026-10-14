#!/usr/bin/env bash

# Check Mesa's shared source and versioned private Rust crate bundle.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

nickel export --format json >"${temporary}/result.json" <<EOF_NICKEL
let package_set = import "${repo_root}/bobrpkgs.ncl" in
let source = fun name => fun version => fun hash => {
  include name,
  include version,
  tag = "Source",
  object_hash = hash,
  origin = { tag = "Http", url = "https://example.invalid/%{name}.tar.xz" },
} in
let summary = fun packages => {
  source = packages.mesa_src,
  mesa = {
    name = packages.mesa.name,
    source = packages.mesa.inputs.source,
    rust_crates_name = packages.mesa.inputs.rust_crates.name,
    rust_crate_inputs = std.record.fields packages.mesa.inputs.rust_crates.inputs,
    has_version = std.record.has_field "version" packages.mesa,
    has_source_object_hash = std.record.has_field "source_object_hash" packages.mesa,
  },
  guest = {
    name = packages.mesa_guest.name,
    source = packages.mesa_guest.inputs.source,
    has_version = std.record.has_field "version" packages.mesa_guest,
    has_source_object_hash = std.record.has_field "source_object_hash" packages.mesa_guest,
  },
} in
let base_packages = package_set [] in
{
  original = summary base_packages,
  shared_source = summary (package_set [fun _final => fun prev => {
    mesa_src = source "mesa-src-27.2.3" "27.2.3" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  }]),
  mesa_input = summary (package_set [fun _final => fun prev => {
    mesa = prev.mesa & {
      inputs.source | force = source "mesa-full-custom" "28.3.4" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    },
  }]),
  guest_input = summary (package_set [fun _final => fun prev => {
    mesa_guest = prev.mesa_guest & {
      inputs.source | force = source "mesa-guest-custom" "29.4.5" "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    },
  }]),
}
EOF_NICKEL

jq -e '
  .original.source.name == "mesa-src-26.1.4"
  and .original.mesa.name == "mesa-26.1.4"
  and .original.mesa.source.name == .original.source.name
  and .original.mesa.rust_crates_name == "mesa-rust-crates-26.1.4"
  and (.original.mesa.rust_crate_inputs | length) > 0
  and .original.guest.name == "mesa-guest-26.1.4"
  and .original.guest.source.name == .original.source.name
  and (.original.mesa.has_version | not)
  and (.original.mesa.has_source_object_hash | not)
  and (.original.guest.has_version | not)
  and (.original.guest.has_source_object_hash | not)
  and .shared_source.mesa.name == "mesa-27.2.3"
  and .shared_source.mesa.source.name == "mesa-src-27.2.3"
  and .shared_source.mesa.rust_crates_name == "mesa-rust-crates-27.2.3"
  and .shared_source.guest.name == "mesa-guest-27.2.3"
  and .shared_source.guest.source.name == "mesa-src-27.2.3"
  and .mesa_input.source.name == .original.source.name
  and .mesa_input.mesa.name == "mesa-28.3.4"
  and .mesa_input.mesa.source.name == "mesa-full-custom"
  and .mesa_input.mesa.rust_crates_name == "mesa-rust-crates-28.3.4"
  and .mesa_input.guest.name == .original.guest.name
  and .mesa_input.guest.source.name == .original.guest.source.name
  and .guest_input.source.name == .original.source.name
  and .guest_input.mesa.name == .original.mesa.name
  and .guest_input.mesa.source.name == .original.mesa.source.name
  and .guest_input.mesa.rust_crates_name == .original.mesa.rust_crates_name
  and .guest_input.guest.name == "mesa-guest-29.4.5"
  and .guest_input.guest.source.name == "mesa-guest-custom"
' "${temporary}/result.json" >/dev/null

echo "Mesa Source tests passed (shared archive and versioned Rust bundle)"
