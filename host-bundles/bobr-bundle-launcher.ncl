let recipe = import "../recipe-lib.ncl" in

# Production packages for the static launchers published by bobr releases.
# Http Source normalizes an archive containing one top-level directory before
# its object hash is checked, so the hashes below identify trees rooted at
# usr/libexec rather than the compressed release assets themselves.
#
# The v0.1.9 SHA256SUMS archive digests used to verify the downloads while
# updating this recipe are:
# - x86_64: 5a1321f55e3d87f8b24552c5bb64b38dfd5ec671c80827e5f9ffc29f02c11c9e
# - aarch64: 021aa0b2418b225aded6108cf493409b3c174cf7b3eab9f8de5c6098e4213af1
fun _pkgs =>
  let mk_launcher = fun arch_slug =>
    fun target =>
      fun default_source_object_hash =>
        {
          version | default = "0.1.9",
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
                url = "https://github.com/aleksey-makarov/bobr/releases/download/v%{version}/bobr-bundle-launcher-v%{version}-%{target}.tar.xz",
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
      "13cb07978902634c69c42a1b1affadc6b819d6239beb37e136a1856875e587ff"
  in

  let bobr_bundle_launcher_host_aarch64 =
    mk_launcher
      "aarch64"
      "aarch64-unknown-linux-musl"
      "a2f86b842257e85e9c8fa765fadb04b4743b599b660c207fb4440449ee206a48"
  in

  {
    include [
      bobr_bundle_launcher_host_x86_64,
      bobr_bundle_launcher_host_aarch64,
    ],
  }
