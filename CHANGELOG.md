# Changelog

## 0.1.11

- Added request v6 profiles with independent local and remote mapping/content
  providers, and composable output repository presets.
- Made package-set construction and ordered build goals explicit in Nickel
  profiles, with repeatable `--target` overrides for one-off selections.
- Renamed the Autotools `in-tree` recipe option to `in_tree` throughout
  lowering and build-script configuration.
- Switched the HostBundle launcher to native builds from its published source
  crate, with a static musl runtime instead of prebuilt release assets.
- Added a standalone check suite and GitHub CI with pinned Nickel formatting.
- Added build-context logs for store comparisons and progress/timing reports
  for request generation and repository publication.
- Fixed Python source downloads using PyPI file service URLs.

## 0.1.10

- Standardized OS images, HostBundles, toolchains, and packages on `/usr/lib`;
  `/usr/lib64` is now a compatibility symlink.
- Added per-package runtime-closure testing and audited runtime dependencies
  across the package set.
- Added local repository configuration and separated Bobr installation from
  world rebuilding.
- Added output repository profiles and post-build publication through
  `bobr-repo`.
- Split shipped artifacts into the `world` target while keeping acceptance
  tests in `test_all`.
- Removed the legacy LLVM 18 toolchain and clarified GCC runtime components.
- Improved local build, store comparison, and guest diagnostic tooling.
