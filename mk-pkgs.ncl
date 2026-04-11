let base_modules = [
  import "host-image.ncl",
  import "buildscripts/autotools.ncl",
  import "buildscripts/gnu-make.ncl",
  import "buildscripts/meson.ncl",
  import "binutils.ncl",
  import "bzip2.ncl",
  import "linux.ncl",
  import "xz.ncl",
  import "lz4.ncl",
  import "zstd.ncl",
  import "file.ncl",
  import "readline.ncl",
  import "attr.ncl",
  import "acl.ncl",
  import "libxcrypt.ncl",
  import "shadow.ncl",
  import "ncurses.ncl",
  import "less.ncl",
  import "zlib.ncl",
  import "elfutils.ncl",
  import "make.ncl",
  import "coreutils.ncl",
  import "sed.ncl",
  import "grep.ncl",
  import "gzip.ncl",
  import "tar.ncl",
  import "patch.ncl",
  import "findutils.ncl",
  import "diffutils.ncl",
  import "m4.ncl",
  import "python.ncl",
  import "bash.ncl",
  import "flex.ncl",
  import "gawk.ncl",
  import "bison.ncl",
  import "gperf.ncl",
  import "bc.ncl",
  import "expat.ncl",
  import "libffi.ncl",
  import "pkgconf.ncl",
  import "gmp.ncl",
  import "mpfr.ncl",
  import "mpc.ncl",
  import "libcap.ncl",
  import "gcc.ncl",
  import "glibc.ncl",
  import "base-filesystem.ncl",
  import "qemu/runtime-files.ncl",
  import "qemu/kernel.ncl",
  import "qemu/rootfs.ncl",
  import "system-image-0.ncl",
  import "system-image-1.ncl",
  import "system-image.ncl",
  import "tests/test-image.ncl",
  import "tests/test-reports.ncl",
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
