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
#   `bobr` JSON request
# - helper scripts such as `bobr-list-pkgs.sh` inspect the fields of
#   `(mkPkgs [])` directly
#
# Do not run `nickel export` on `(import "pkgs.ncl") []` directly. Exporting
# the complete package set serializes the entire fixed-point recipe graph and
# can exhaust system memory. Use `std.record.fields`, `tools/bobr-list-pkgs.sh`,
# `request.ncl`, or `tools/bobr-build.sh --dry-run` for targeted inspection.
let base_modules = [
  import "accountsservice/accountsservice.ncl",
  import "acl.ncl",
  import "adwaita-icon-theme.ncl",
  import "alsa-lib.ncl",
  import "appstream/appstream.ncl",
  import "at-spi2-core.ncl",
  import "attr.ncl",
  import "autoconf.ncl",
  import "automake.ncl",
  import "bash.ncl",
  import "bc.ncl",
  import "bibata-cursors/bibata-cursors.ncl",
  import "bindgen/bindgen.ncl",
  import "binutils.ncl",
  import "bison.ncl",
  import "blueprint-compiler.ncl",
  import "bzip2/bzip2.ncl",
  import "cairo.ncl",
  import "cbindgen/cbindgen.ncl",
  import "cmake.ncl",
  import "colord-gtk.ncl",
  import "colord.ncl",
  import "coreutils.ncl",
  import "cups.ncl",
  import "curl.ncl",
  import "dbus.ncl",
  import "dconf.ncl",
  import "dejagnu/dejagnu.ncl",
  import "dejavu/dejavu.ncl",
  import "diffutils.ncl",
  import "docutils.ncl",
  import "duktape/duktape.ncl",
  import "e2fsprogs/e2fsprogs.ncl",
  import "elfutils.ncl",
  import "erofs-utils.ncl",
  import "evolution-data-server.ncl",
  import "expat.ncl",
  import "expect/expect.ncl",
  import "file.ncl",
  import "findutils.ncl",
  import "flex.ncl",
  import "fontconfig.ncl",
  import "freetype.ncl",
  import "fribidi.ncl",
  import "gawk.ncl",
  import "gcc.ncl",
  import "gcr.ncl",
  import "gdbm.ncl",
  import "gdk-pixbuf.ncl",
  import "gdm/gdm.ncl",
  import "geoclue.ncl",
  import "geocode-glib.ncl",
  import "gettext.ncl",
  import "gjs.ncl",
  import "glib.ncl",
  import "glibc/glibc-locales.ncl",
  import "glibc/glibc.ncl",
  import "glmark2.ncl",
  import "glslang.ncl",
  import "glu.ncl",
  import "glycin/glycin.ncl",
  import "gmp.ncl",
  import "gnome-bluetooth.ncl",
  import "gnome-control-center.ncl",
  import "gnome-desktop.ncl",
  import "gnome-online-accounts.ncl",
  import "gnome-session.ncl",
  import "gnome-settings-daemon.ncl",
  import "gnome-shell/gnome-shell.ncl",
  import "gnutls.ncl",
  import "gobject-introspection.ncl",
  import "gperf.ncl",
  import "graphene.ncl",
  import "grep.ncl",
  import "groff.ncl",
  import "grub.ncl",
  import "gsettings-desktop-schemas.ncl",
  import "gsound.ncl",
  import "gtk4.ncl",
  import "gweather-locations.ncl",
  import "gzip.ncl",
  import "harfbuzz.ncl",
  import "hicolor-icon-theme.ncl",
  import "hwdata/hwdata.ncl",
  import "iana-etc/iana-etc.ncl",
  import "ibus/ibus.ncl",
  import "icu.ncl",
  import "inetutils.ncl",
  import "intltool.ncl",
  import "iproute2.ncl",
  import "iso-codes.ncl",
  import "json-glib.ncl",
  import "kbd/kbd.ncl",
  import "kmod.ncl",
  import "kmscube.ncl",
  import "krb5.ncl",
  import "lcms2.ncl",
  import "less.ncl",
  import "libadwaita.ncl",
  import "libcanberra.ncl",
  import "libcap.ncl",
  import "libclc.ncl",
  import "libdecor.ncl",
  import "libdisplay-info.ncl",
  import "libdrm.ncl",
  import "libei.ncl",
  import "libepoxy.ncl",
  import "libevdev.ncl",
  import "libffi.ncl",
  import "libgcrypt.ncl",
  import "libglvnd.ncl",
  import "libgpg-error.ncl",
  import "libgtop.ncl",
  import "libgudev.ncl",
  import "libgusb.ncl",
  import "libgweather.ncl",
  import "libical.ncl",
  import "libinput.ncl",
  import "libjpeg-turbo.ncl",
  import "libndp.ncl",
  import "libnma/libnma.ncl",
  import "libnotify.ncl",
  import "libogg.ncl",
  import "libpipeline.ncl",
  import "libpng.ncl",
  import "libpsl.ncl",
  import "libpwquality.ncl",
  import "librest.ncl",
  import "librsvg/librsvg.ncl",
  import "libsass.ncl",
  import "libseccomp.ncl",
  import "libsecret.ncl",
  import "libslirp.ncl",
  import "libsndfile.ncl",
  import "libsoup.ncl",
  import "libtasn1.ncl",
  import "libtiff.ncl",
  import "libtirpc.ncl",
  import "libtool.ncl",
  import "libunistring.ncl",
  import "libusb.ncl",
  import "libvorbis.ncl",
  import "libwacom.ncl",
  import "libxcrypt.ncl",
  import "libxcvt.ncl",
  import "libxkbcommon.ncl",
  import "libxml2.ncl",
  import "libxmlb.ncl",
  import "libxslt.ncl",
  import "libyaml.ncl",
  import "linux-pam.ncl",
  import "llvm-bin.ncl",
  import "lz4.ncl",
  import "m4.ncl",
  import "make.ncl",
  import "man-db.ncl",
  import "man-pages/man-pages.ncl",
  import "mc/mc.ncl",
  import "mesa/mesa-demos.ncl",
  import "mesa/mesa.ncl",
  import "meson.ncl",
  import "modemmanager.ncl",
  import "mozjs/mozjs.ncl",
  import "mpc.ncl",
  import "mpfr.ncl",
  import "mtdev.ncl",
  import "mutter.ncl",
  import "nasm.ncl",
  import "ncurses.ncl",
  import "nettle.ncl",
  import "networkmanager.ncl",
  import "nghttp2.ncl",
  import "ninja.ncl",
  import "nspr/nspr.ncl",
  import "nss/nss.ncl",
  import "openssh.ncl",
  import "openssl/openssl.ncl",
  import "p11-kit.ncl",
  import "pango.ncl",
  import "patch.ncl",
  import "pcre2.ncl",
  import "perl/perl.ncl",
  import "pixman.ncl",
  import "pkgconf.ncl",
  import "polkit.ncl",
  import "popt.ncl",
  import "procps-ng.ncl",
  import "psmisc.ncl",
  import "pulseaudio.ncl",
  import "pygobject.ncl",
  import "python/python.ncl",
  import "qemu.ncl",
  import "readline.ncl",
  import "rsync.ncl",
  import "rust-bin.ncl",
  import "samba.ncl",
  import "sassc.ncl",
  import "sdl2-compat.ncl",
  import "sdl3.ncl",
  import "seatd.ncl",
  import "sed.ncl",
  import "shadow.ncl",
  import "shared-mime-info.ncl",
  import "slang/slang.ncl",
  import "spirv-headers-llvm.ncl",
  import "spirv-headers.ncl",
  import "spirv-llvm-translator.ncl",
  import "spirv-tools.ncl",
  import "sqlite.ncl",
  import "systemd.ncl",
  import "tar.ncl",
  import "tcl/tcl.ncl",
  import "tecla.ncl",
  import "texinfo.ncl",
  import "tzdata.ncl",
  import "udisks.ncl",
  import "upower.ncl",
  import "util-linux.ncl",
  import "vala.ncl",
  import "vim.ncl",
  import "virglrenderer.ncl",
  import "vulkan-headers.ncl",
  import "vulkan-loader.ncl",
  import "vulkan-tools.ncl",
  import "wayland-protocols.ncl",
  import "wayland.ncl",
  import "weston.ncl",
  import "xcompose-data.ncl",
  import "xkeyboard-config.ncl",
  import "xz.ncl",
  import "zlib.ncl",
  import "zstd.ncl",

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
