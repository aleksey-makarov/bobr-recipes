let lib = import "lib.ncl" in
let recipe = import "recipe-lib.ncl" in

let base_layers = [
  (fun final => fun prev =>
    {
      host_image =
        recipe.container_image lib.host_image_name {
          image = lib.host_image.image,
          digest = lib.host_image.digest,
        },
    }),
  (fun final => fun prev => (import "buildscripts/autotools.ncl") final),
  (fun final => fun prev => (import "binutils.ncl") final),
  (fun final => fun prev => (import "linux.ncl") final),
  (fun final => fun prev => (import "make.ncl") final),
  (fun final => fun prev => (import "coreutils.ncl") final),
  (fun final => fun prev => (import "sed.ncl") final),
  (fun final => fun prev => (import "grep.ncl") final),
  (fun final => fun prev => (import "gzip.ncl") final),
  (fun final => fun prev => (import "tar.ncl") final),
  (fun final => fun prev => (import "patch.ncl") final),
  (fun final => fun prev => (import "findutils.ncl") final),
  (fun final => fun prev => (import "diffutils.ncl") final),
  (fun final => fun prev => (import "m4.ncl") final),
  (fun final => fun prev => (import "python.ncl") final),
  (fun final => fun prev => (import "bash.ncl") final),
  (fun final => fun prev => (import "gawk.ncl") final),
  (fun final => fun prev => (import "bison.ncl") final),
  (fun final => fun prev => (import "gmp.ncl") final),
  (fun final => fun prev => (import "mpfr.ncl") final),
  (fun final => fun prev => (import "mpc.ncl") final),
  (fun final => fun prev => (import "gcc.ncl") final),
  (fun final => fun prev => (import "glibc.ncl") final),
  (fun final => fun prev => (import "base-filesystem.ncl") final),
  (fun final => fun prev => (import "system-image-0.ncl") final),
  (fun final => fun prev => (import "system-image-1.ncl") final),
  (fun final => fun prev => (import "system-image.ncl") final),
  (fun final => fun prev => (import "tests/test-image.ncl") final),
  (fun final => fun prev => (import "tests/test-reports.ncl") final),
] in

let replace_fields =
  fun base =>
  fun patch =>
    let patch_fields = std.record.fields patch in

    let base_without_patch =
      std.array.fold_left
        (
          fun acc field =>
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
  let layers = std.array.concat base_layers overlays in

  let rec final =
    std.array.fold_left
      (fun prev layer => replace_fields prev (layer final prev))
      {}
      layers
  in

  final
