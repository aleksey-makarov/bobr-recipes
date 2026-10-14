# Rust crate vendoring helpers.
#
# `crate_sources lock` turns a parsed `Cargo.lock` (imported `as 'Toml`) into an
# array of Http `Source` nodes, one per crates.io registry crate. A crate's
# `object_hash` is exactly the `checksum` from `Cargo.lock`: the fsobj-hash of a
# non-executable file equals its SHA-256, and crates.io serves each version as
# an immutable `.crate` file. Source/input names are sanitized to the
# `[A-Za-z0-9_]` that bobr input names allow (the real name/version stay in the
# URL). Non-registry entries (the package itself, path and git dependencies) are
# skipped -- they carry no `source = "registry+..."`.
#
# `vendor_inputs lock` returns the input record for a public `Bundle` recipe;
# `vendor_bundle name lock` constructs a complete private Bundle when no extra
# overridable metadata is needed. The recipe passes that Bundle explicitly as
# `inputs.crates`. The Cargo pipeline unpacks it into a `vendor/` tree and uses
# offline source replacement.
let san = fun s =>
  s
  |> std.string.replace "-" "_"
  |> std.string.replace "." "_"
  |> std.string.replace "+" "_"
in
let is_crates_io = fun p =>
  (std.record.get_or "source" "" p) == "registry+https://github.com/rust-lang/crates.io-index"
in
let crate_sources_fn = fun lock =>
  lock.package
  |> std.array.filter is_crates_io
  |> std.array.map (fun p =>
    {
      name = "crate_%{san p.name}_%{san p.version}",
      tag = "Source",
      object_hash = p.checksum,
      origin = {
        tag = "Http",
        url = "https://static.crates.io/crates/%{p.name}/%{p.name}-%{p.version}.crate",
      },
    }
  )
in
let vendor_inputs_fn = fun lock =>
  std.array.fold_left
    (fun acc => fun src => std.record.insert src.name src acc)
    {}
    (crate_sources_fn lock)
in
{
  crate_sources = crate_sources_fn,
  vendor_inputs = vendor_inputs_fn,

  matching_version = fun package_name =>
    fun source_version =>
      fun crates_version =>
        if source_version == crates_version then
          source_version
        else
          std.fail_with "%{package_name}: source version '%{source_version}' must match vendored crates version '%{crates_version}'",

  # Custom Meson/Autotools recipes which invoke Cargo use this after creating
  # their offline vendor directory. It checks the lockfile shipped by the
  # unpacked upstream source against the available vendored dependency set.
  verify_lock_step = {
    name = "bobr_verify_cargo_lock",
    run_as = "build-user",
    cwd = "@{build}/source",
    argv = [
      "/bin/sh",
      "-ec",
      "cargo metadata --format-version 1 --locked --offline >/dev/null",
    ],
  },

  vendor_bundle = fun bundle_name =>
    fun lock =>
      {
        name = bundle_name,
        tag = "Bundle",
        config = {},
        inputs = vendor_inputs_fn lock,
      },
}
