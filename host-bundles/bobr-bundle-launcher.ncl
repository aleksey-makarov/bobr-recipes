let recipe = import "../recipe-lib.ncl" in

# Production packages for the static launchers published by bobr releases.
# Http Source normalizes an archive containing one top-level directory before
# its object hash is checked, so the hashes below identify trees rooted at
# usr/libexec rather than the compressed release assets themselves.
#
# The v0.1.10 SHA256SUMS archive digests used to verify the downloads while
# updating this recipe are:
# - x86_64: ae3c5b3f5ab6d8f862e40ddb27d204fafae5e6cf7d4a92e7208ed368389ba56d
# - aarch64: 2e4a36d24bee3d7740058e74b6a31a30919a8338f475648c9e369d43a30b12d1
fun _pkgs =>
  let mk_launcher = fun arch_slug =>
    fun target =>
      fun default_source_object_hash =>
        {
          version | default = "0.1.10",
          source_object_hash | default = default_source_object_hash,
          name = "bobr-bundle-launcher-host-%{arch_slug}-%{version}",
          tag = "FsTreeImport",
          config = {
            install = {
              rules = [recipe.install.fs_tree_root_default_rule],
            },
          },
          inputs = {
            input = {
              name = "bobr-bundle-launcher-src-%{version}-%{target}",
              tag = "Source",
              object_hash = source_object_hash,
              origin = {
                tag = "Http",
                url = "https://github.com/aleksey-makarov/bobr/releases/download/v%{version}/bobr-bundle-launcher-%{target}.tar.xz",
                unpack = true,
                archive_format = "tar-xz",
              },
            },
          },
        }
  in

  let bobr_bundle_launcher_host_x86_64 =
    mk_launcher
      "x86-64"
      "x86_64-unknown-linux-musl"
      "a388c0801dba23a9560f7b2079e17bc21f1a3a23624391134f75758c8d8ab989"
  in

  let bobr_bundle_launcher_host_aarch64 =
    mk_launcher
      "aarch64"
      "aarch64-unknown-linux-musl"
      "661e9d494ca63abf306044d2cdc8940c3d036e87fca2a27cdf68802ae5d82e46"
  in

  {
    include [
      bobr_bundle_launcher_host_x86_64,
      bobr_bundle_launcher_host_aarch64,
    ],
  }
