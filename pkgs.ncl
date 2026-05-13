# Exports `mkPkgs`, a function `Array Overlay -> PackageSet`.
#
# Usage:
# - `(import "pkgs.ncl") []`
#   builds the default fixed-point package set with no overlays.
# - `(import "pkgs.ncl") [overlay1, overlay2]`
#   builds the same package set, then applies overlays in order.
#
# Each overlay is called as `overlay final prev`, where:
# - `final` is the final package set after all overlays
# - `prev` is the package set after the previous overlay step
#
# Typical entry points built on top of this:
# - `request.ncl` selects one attribute from `(mkPkgs [])` and lowers it to an
#   `mbuild` JSON request
# - helper scripts such as `list-pkgs-attrs.sh` inspect the fields of
#   `(mkPkgs [])` directly
let base_modules = [
  import "images.ncl",
  import "image-rootfs.ncl",
  import "iana-etc.ncl",
  import "binutils.ncl",
  import "bzip2.ncl",
  import "linux/linux.ncl",
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
  import "gdbm.ncl",
  import "gettext.ncl",
  import "groff.ncl",
  import "grub.ncl",
  import "autoconf.ncl",
  import "automake.ncl",
  import "libtool.ncl",
  import "man-db.ncl",
  import "make.ncl",
  import "coreutils.ncl",
  import "sed.ncl",
  import "grep.ncl",
  import "gzip.ncl",
  import "inetutils.ncl",
  import "iproute2.ncl",
  import "dbus.ncl",
  import "systemd.ncl",
  import "tar.ncl",
  import "patch.ncl",
  import "perl.ncl",
  import "xml-parser.ncl",
  import "intltool.ncl",
  import "openssl.ncl",
  import "kbd.ncl",
  import "kmod.ncl",
  import "procps-ng.ncl",
  import "psmisc.ncl",
  import "findutils.ncl",
  import "diffutils.ncl",
  import "libpipeline.ncl",
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
  import "man-pages.ncl",
  import "mpfr.ncl",
  import "mpc.ncl",
  import "libcap.ncl",
  import "gcc.ncl",
  import "glibc.ncl",
  import "filesystem/base-filesystem.ncl",
  import "filesystem/runtime-files.ncl",
  import "linux/kernel.ncl",
  import "filesystem/qemu_rootfs.ncl",
  import "system-rootfs.ncl",
  import "tcl.ncl",
  import "expect.ncl",
  import "dejagnu.ncl",
  import "texinfo.ncl",
  import "util-linux.ncl",
  import "e2fsprogs.ncl",
  import "tests/test-rootfs.ncl",
  import "tests/test-reports.ncl",
  import "vim.ncl",
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
