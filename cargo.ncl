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
# `vendor_bundle name lock` collects those crate sources into one `Bundle`
# object: a plain directory of `.crate` files (one hardlink each), so a Rust
# package recipe takes a single input instead of one bind mount per crate. The
# recipe's `pre_configure` unpacks that directory into a cargo `vendor/` tree
# with offline source replacement.
let san = fun s =>
  s
  |> std.string.replace "-" "_"
  |> std.string.replace "." "_"
  |> std.string.replace "+" "_"
in
let is_crates_io = fun p =>
  (std.record.get_or "source" "" p)
  == "registry+https://github.com/rust-lang/crates.io-index"
in
let crate_sources_fn = fun lock =>
  lock.package
  |> std.array.filter is_crates_io
  |> std.array.map
    (fun p =>
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
{
  crate_sources = crate_sources_fn,

  vendor_bundle = fun bundle_name =>
    fun lock =>
      {
        name = bundle_name,
        tag = "Bundle",
        config = {},
        inputs =
          std.array.fold_left
            (fun acc => fun src => std.record.insert src.name src acc)
            {}
            (crate_sources_fn lock),
      },
}
