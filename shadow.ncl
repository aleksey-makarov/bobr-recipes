let recipe = import "recipe-lib.ncl" in
let hashes = {
  "4.18.0" = "06a05b0ff7c6a9a249f9c5cf1783a122d6f5a4b1b0a7f7c00eea73240fb5cce1",
  "4.19.4" = "9569b68a1283e8f5a2187aef9e7ea4dd3e6fbc60991f115cf217b6a22f85c0ad",
}
in

fun pkgs =>
  let shadow_src = fun version =>
    {
      name = "shadow-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://github.com/shadow-maint/shadow/releases/download/%{version}/shadow-%{version}.tar.xz",
      },
    }
  in

  let shadow_build_rootfs = {
    name = "shadow-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.libxcrypt,
        pkgs.linux_pam,
        pkgs.pkgconf,
        pkgs.systemd_dev,
      ],
  }
  in

  let shadow = {
    version | default = "4.19.4",
    name = "shadow-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      pre_configure = [
        {
          name = "prepare_shadow_sources",
          run_as = "build-user",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              sed -i 's/groups$(EXEEXT) //' src/Makefile.in
              find man -name Makefile.in -exec sed -i 's/groups\\.1 / /' {} ';'
              find man -name Makefile.in -exec sed -i 's/getspnam\\.3 / /' {} ';'
              find man -name Makefile.in -exec sed -i 's/passwd\\.5 / /' {} ';'
              sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
                  -e 's:/var/spool/mail:/var/mail:' \
                  -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
                  -i etc/login.defs
            "%,
          ],
        },
      ],
      configure_args = [
        "--sysconfdir=/etc",
        "--sbindir=/usr/bin",
        "--disable-static",
        # Build login/su/passwd against PAM so they consult /etc/pam.d/*. This is
        # required for logind: login's PAM session stack runs pam_systemd, which
        # registers the session (without PAM, login authenticates on its own and
        # never opens a PAM session). PAM-enabled tools other than `login` need
        # their own /etc/pam.d/<tool> file or they fall through to `other`
        # (deny); only `login` is provided for now.
        "--with-libpam",
        "--with-bcrypt",
        "--with-yescrypt",
        "--without-libbsd",
        "--with-group-name-max-length=32",
      ],
      make_args = [
        "exec_prefix=/usr",
        "usbindir=/usr/bin",
      ],
      post_install = {
        name = "install_man_pages",
        run_as = "root",
        cwd = "@{build}/build",
        argv = [
          "/bin/sh",
          "-ec",
          # Drop shadow's own /etc/pam.d/login: we ship our own (with
          # pam_systemd) in system-runtime-files, and shadow's references the
          # removed pam_securetty.so. The other shadow pam.d files (su, passwd,
          # ...) are unique and defer to our /etc/pam.d/system-auth, so keep them.
          m%"
            make DESTDIR="@{out}" -C man install-man
            rm -f "@{out}/etc/pam.d/login"
          "%,
        ],
      },
    },
    inputs = {
      _rootfs = shadow_build_rootfs,
      source = shadow_src version,
    },
  }
  in

  {
    include [
      shadow,
    ],
  }
