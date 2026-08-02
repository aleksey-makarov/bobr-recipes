let recipe = import "../recipe-lib.ncl" in

# Production packages for the static launchers published by bobr releases.
# Http Source normalizes an archive containing one top-level directory before
# its object hash is checked, so the hashes below identify trees rooted at
# usr/libexec rather than the compressed release assets themselves.
#
# The v0.1.4 SHA256SUMS archive digests used to verify the downloads while
# updating this recipe are:
# - x86_64: 7aa2f27f036dbe4c9c80eeea59e03381ecdf255cd184276bf5cad2e3a0fb8505
# - aarch64: 515061d06ad7c279cf5cc72aa39caf4bc8e57e7cc820e2937b3ca8f5d9f13854
fun _pkgs =>
  let mk_launcher = fun arch_slug =>
    fun target =>
      fun default_source_object_hash =>
        {
          version | default = "0.1.4",
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
      "b9e06e9889fec73e44e98a87aa4a5da2185a042c6afb267a23bf96075ffe6678"
  in

  let bobr_bundle_launcher_host_aarch64 =
    mk_launcher
      "aarch64"
      "aarch64-unknown-linux-musl"
      "16398b622049fbef11b62ea1f9ce8f1d09915e371e14610b2c6a185f4524e1b1"
  in

  {
    include [
      bobr_bundle_launcher_host_x86_64,
      bobr_bundle_launcher_host_aarch64,
    ],
  }
