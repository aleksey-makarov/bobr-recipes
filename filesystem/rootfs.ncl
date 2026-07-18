let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let rootfs_deps = [
    pkgs.system_runtime_files,
    pkgs.man_pages,
    pkgs.iana_etc,
    pkgs.tzdata,
    pkgs.linux_headers,
    pkgs.linux_modules,
    pkgs.glibc,
    pkgs.zlib,
    pkgs.bzip2,
    pkgs.xz,
    pkgs.lz4,
    pkgs.zstd,
    pkgs.file,
    pkgs.readline,
    pkgs.attr,
    pkgs.acl,
    pkgs.libcap,
    pkgs.libffi,
    pkgs.libxcrypt,
    pkgs.expat,
    pkgs.pcre2,
    pkgs.ncurses,
    pkgs.bash,
    pkgs.bc,
    pkgs.binutils,
    pkgs.gmp,
    pkgs.mpfr,
    pkgs.mpc,
    pkgs.bison,
    pkgs.coreutils,
    pkgs.diffutils,
    pkgs.elfutils,
    pkgs.flex,
    pkgs.gdbm,
    pkgs.gawk,
    pkgs.gcc,
    pkgs.gettext,
    pkgs.gperf,
    pkgs.grep,
    pkgs.groff,
    pkgs.grub,
    pkgs.autoconf,
    pkgs.automake,
    pkgs.dbus,
    pkgs.systemd,
    pkgs.tcl,
    pkgs.expect,
    pkgs.dejagnu,
    pkgs.less,
    pkgs.inetutils,
    pkgs.iproute2,
    pkgs.intltool,
    pkgs.openssl,
    pkgs.kbd,
    pkgs.kmod,
    pkgs.libtool,
    pkgs.libpipeline,
    pkgs.m4,
    pkgs.man_db,
    pkgs.make,
    pkgs.patch,
    pkgs.perl,
    pkgs.pkgconf,
    pkgs.psmisc,
    pkgs.python,
    pkgs.xml_parser,
    pkgs.sed,
    pkgs.shadow,
    # libpam + PAM modules (pam_unix/pam_systemd/...) and helpers. systemd ships
    # pam_systemd.so which links libpam.so.0, so the rootfs must carry PAM or
    # that module is unresolved; also the basis for login sessions.
    pkgs.linux_pam,
    pkgs.procps_ng,
    pkgs.findutils,
    pkgs.gzip,
    pkgs.rsync,
    pkgs.tar,
    pkgs.texinfo,
    pkgs.util_linux,
    pkgs.e2fsprogs,
    pkgs.vim,
    # mc links libglib-2.0; glib (and other transitive runtime deps) are pulled
    # automatically by the RootfsClosure below, so they need not be listed here.
    pkgs.mc,
    pkgs.openssh,
  ]
  in
  # Unit enablement is NOT done here. systemd applies preset policy at first
  # boot ("systemd will enable/disable all units according to preset policy",
  # systemd.preset(5)); with an empty /etc/machine-id on a volatile-overlay /etc
  # every boot is a first boot, so presets are (re)applied on every boot. Units
  # we want on by default that the vendor preset does not cover go in a
  # /usr/lib/systemd/system-preset/*.preset file, not enabled by hand or at build.
  # RootfsClosure: base_filesystem + the runtime closure of the listed roots.
  # The roots are the tools/packages we want in the image (a self-hosting dev
  # toolchain, so they stay explicit -- runtime closure would otherwise pull
  # only *-libs splits without headers); their transitive runtime deps are added
  # automatically, so pure-library deps no longer need hand-listing.
  let rootfs = {
    name = "rootfs",
    tag = "RootfsClosure",
    config = {},
    inputs = recipe.numbered_inputs rootfs_deps,
  }
  in
  let erofs_rootfs =
    recipe.erofs_image
      pkgs
      {
        name = "erofs-rootfs",
        tree = rootfs,
      }
  in

  {
    include [
      rootfs,
      erofs_rootfs,
    ],
  }
