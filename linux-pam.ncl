let recipe = import "recipe-lib.ncl" in
let version = "1.6.1" in

fun pkgs =>
  let linux_pam_src = {
    name = "linux-pam-src-%{version}",
    tag = "Source",
    object_hash = "4705fec079b3fc8cd884eb0c2ceee1819cbf0fed5678f92850d717b50aba06d6",
    origin = {
      tag = "Http",
      url = "https://github.com/linux-pam/linux-pam/releases/download/v%{version}/Linux-PAM-%{version}.tar.xz",
    },
  }
  in

  # Linux-PAM: libpam + the base modules (pam_unix, pam_permit, pam_env,
  # pam_loginuid, ...) needed for a login session. This is the prerequisite for
  # systemd's pam_systemd.so (built separately once systemd is rebuilt with
  # -Dpam=enabled): pam_systemd registers the logind session at login. Modules
  # install to $libdir/security (= /usr/lib/security). pam_unix links libcrypt
  # (libxcrypt) to verify /etc/shadow. Docs/NLS/selinux/audit/nis/db/econf are
  # off to avoid xsltproc/gettext/libselinux/libaudit/libdb/libeconf deps we do
  # not carry. flex/bison are for the legacy pam_conv1 config converter.
  let linux_pam = {
    name = "linux-pam-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libxcrypt,
        pkgs.pkgconf,
        pkgs.flex,
        pkgs.bison,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.libxcrypt_libs,
      ],
    },
    config = {
      configure_args = [
        "--sysconfdir=/etc",
        "--sbindir=/usr/bin",
        # Must be explicit: with the autotools default (${exec_prefix}/lib) PAM's
        # configure.ac rewrites libdir to a top-level /lib64 on x86_64, which
        # collides with the merged-usr /lib64 -> usr/lib symlink at TreeMerge.
        # /usr/lib also puts the modules in /usr/lib/security.
        "--libdir=/usr/lib",
        "--disable-static",
        "--disable-nls",
        "--disable-doc",
        "--disable-regenerate-docu",
        "--disable-selinux",
        "--disable-audit",
        "--disable-nis",
        "--disable-db",
        "--disable-econf",
        "--disable-examples",
      ],
      # PAM ships a non-empty default /etc/environment; the base system already
      # provides the canonical (empty) one, so drop PAM's copy to avoid a
      # TreeMerge conflict wherever linux-pam is merged. pam_env reads
      # /etc/environment regardless of which package installs it.
      post_install = {
        name = "drop_default_environment",
        run_as = "root",
        cwd = "@{out}",
        argv = [
          "/bin/sh",
          "-ec",
          "rm -f \"@{out}/etc/environment\"",
        ],
      },
    },
    inputs = {
      source = linux_pam_src,
    },
  }
  in

  # libpam.so alone, for downstream runtime closures (systemd's pam_systemd.so
  # links libpam.so.0). The PAM modules themselves (pam_unix, pam_systemd, ...)
  # live under /usr/lib/security and come from the full `linux_pam` package that
  # the rootfs merges in.
  let linux_pam_libs =
    recipe.split.libs linux_pam "usr/lib/libpam*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      linux_pam,
      linux_pam_libs,
    ],
  }
