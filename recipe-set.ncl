# Exports `mkPkgs`, a function `Array Overlay -> RecipeSet`.
#
# Usage:
# - `(import "recipe-set.ncl") []`
#   builds the default fixed-point package set with no overlays.
# - `(import "recipe-set.ncl") [overlay1, overlay2]`
#   builds the same package set, then applies overlays in order.
#
# Each overlay is called as `overlay final prev`, where:
# - `final` is the final package set after all overlays
# - `prev` is the package set after the previous overlay step
#
# Typical entry points built on top of this:
# - `request.ncl` selects one attribute from `(mkPkgs [])` and lowers it to an
#   `bobr` JSON request
# - helper scripts such as `bobr-list-pkgs.sh` inspect the fields of
#   `(mkPkgs [])` directly
#
# Do not run `nickel export` on `(import "recipe-set.ncl") []` directly. Exporting
# the complete package set serializes the entire fixed-point recipe graph and
# can exhaust system memory. Use `std.record.fields`, `tools/bobr-list-pkgs.sh`,
# `request.ncl`, or `tools/bobr-build.sh --dry-run` for targeted inspection.
let base_modules =
  (import "pkgs/pkgs.ncl")
  @ [
    # Tests
    import "tests/tests.ncl",

    # Linux
    import "linux/linux.ncl",
    import "linux/initrd.ncl",

    # OCI images
    import "oci/image.ncl",
    import "oci/rootfs.ncl",

    # OS images
    import "os/base-filesystem.ncl",
    import "os/qemu_image.ncl",
    import "os/qemu_weston_image.ncl",
    import "os/qemu_gnome_image.ncl",

    # Host-side launcher and application bundles
    import "host-bundles/bobr-bundle-launcher.ncl",
    import "host-bundles/host-bundle-mc.ncl",
    import "host-bundles/host-bundle-test-mesa.ncl",
    import "host-bundles/host-bundle-qemu.ncl",
  ]
in

let replace_fields = fun base =>
  fun patch =>
    let patch_fields = std.record.fields patch in

    let base_without_patch =
      std.array.fold_left
        (fun acc field =>
          if std.record.has_field field acc then
            std.record.remove field acc
          else
            acc
        )
        base
        patch_fields
    in

    base_without_patch & patch
in

fun overlays =>
  let rec final =
    let base =
      std.array.fold_left
        (fun acc module => acc & (module final))
        {}
        base_modules
    in

    std.array.fold_left
      (fun prev overlay => replace_fields prev (overlay final prev))
      base
      overlays
  in

  final
