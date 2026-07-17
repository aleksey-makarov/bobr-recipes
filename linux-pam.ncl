let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let linux_pam_src = fun version => fun hash => {
    name = "linux-pam-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "1.6.1",
    source_object_hash | default = "f8923c740159052d719dbfc2a2f81942d68dd34fcaf61c706a02c9b80feeef8e",
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
      # PAM's `make install` unconditionally installs its own non-empty default
      # /etc/environment (pam_env's `dist_sysconf_DATA = environment`), which
      # would overwrite the canonical empty one the base filesystem provides
      # (present in the overlay's lower layer) -- a non-additive modification.
      # The base file is the authoritative one (pam_env reads whatever is on
      # disk), so stop PAM from installing its copy: drop `environment` from the
      # pam_env Makefile before configure regenerates it. (Edit Makefile.in, not
      # Makefile.am -- automake is not a build dep, so the .am must stay older.)
      pre_configure = {
        name = "drop_pam_env_environment_install",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i 's/^dist_sysconf_DATA = environment$/dist_sysconf_DATA =/' modules/pam_env/Makefile.in",
        ],
      },
    },
    inputs = {
      source = linux_pam_src version source_object_hash,
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
