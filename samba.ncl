# Samba -- we build it only for libsmbclient (smbclient.pc), a hard dependency of
# gnome-control-center's Printers panel (SMB printer discovery). Samba uses a waf
# build driven through a ./configure + make wrapper, built in-tree.
#
# This is a trimmed client build: the AD domain controller, LDAP/ADS, winbind,
# PAM, systemd, JSON audit, GPGME, libarchive and the Python bindings are all
# off, so we avoid pulling in lmdb, jansson, openldap, etc. Samba's internal
# libraries (talloc/tdb/tevent/ldb and bundled Heimdal) are built bundled.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let samba_src = fun version =>
    fun hash =>
      {
        name = "samba-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.samba.org/pub/samba/stable/samba-%{version}.tar.gz",
        },
      }
  in

  let samba = {
    version | default = "4.24.4",
    source_object_hash
      | default
      = "df2c51ab4361ec626ab9988e5946efcca8465bc7afae834291d5558468265ff8",
    name = "samba-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.python,
        pkgs.perl,
        pkgs.parse_yapp,
        pkgs.flex,
        pkgs.bison,
        pkgs.gnutls,
        pkgs.popt,
        pkgs.libtirpc,
        pkgs.gmp,
        pkgs.zlib,
        pkgs.libtasn1,
        pkgs.libxcrypt,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.gnutls,
        pkgs.popt,
        pkgs.libtirpc,
        pkgs.gmp,
        pkgs.zlib,
        pkgs.libtasn1,
        pkgs.libxcrypt_libs,
      ],
    },
    config = {
      # Samba's waf build runs in-tree (bin/).
      "in-tree" = true,
      # Some of Samba's private libraries (e.g. libsmbpasswdparser) are linked
      # against other private libs in /usr/lib/samba but the waf build fails to
      # record a RUNPATH for them (a known Samba bug, Debian #1010922), so at
      # runtime they cannot find their siblings and `ldd` reports them
      # unresolved. Inject the private libdir into the link RUNPATH for every
      # object; the private libs all live there, so this makes them resolvable
      # without exposing the dir globally via ld.so.conf.
      env = {
        LDFLAGS = "-Wl,-rpath,/usr/lib/samba -Wl,--enable-new-dtags",
      },
      configure_args = [
        "--enable-fhs",
        "--sysconfdir=/etc",
        "--localstatedir=/var",
        # merged-usr: /usr/sbin is a symlink to bin.
        "--sbindir=/usr/bin",
        "--bundled-libraries=ALL,!popt",
        "--without-ad-dc",
        "--without-ldb-lmdb",
        "--without-json",
        "--without-ldap",
        "--without-ads",
        "--without-pam",
        "--without-systemd",
        "--without-gpgme",
        "--without-libarchive",
        "--without-winbind",
        "--without-regedit",
        "--without-acl-support",
        "--disable-python",
        "--disable-cups",
        "--disable-iprint",
        "--disable-cephfs",
        "--disable-glusterfs",
        # vfs_snapper needs dbus-1 which we don't ship in this client build.
        "--with-shared-modules=!vfs_snapper",
      ],
      # Samba installs its own var/lock and var/run state directories, but the
      # base filesystem provides those paths as symlinks (var/lock -> ../run/lock,
      # var/run -> ../run); shipping them as directories would collide at the
      # rootfs TreeMerge. Samba creates them fresh (they are not in its build
      # rootfs), so removing them here is an upper-only deletion and the layer
      # stays additive. We do NOT touch /run itself -- it is a sandbox mountpoint
      # and Samba installs nothing there. Also drop the bundled-Heimdal build
      # tools (compile_et, asn1_compile) that collide with krb5's binaries; we
      # ship Samba only for libsmbclient, so its /usr/bin helpers are unneeded.
      post_install = {
        name = "drop_volatile_state_dirs",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          "rm -rf /var/lock /var/run; rm -f /usr/bin/compile_et /usr/bin/asn1_compile",
        ],
      },
    },
    inputs = {
      source = samba_src version source_object_hash,
    },
  }
  in

  { include [ samba ] }
