fun pkgs =>
  let shadow_src = fun version =>
    fun hash =>
    {
      name = "shadow-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://github.com/shadow-maint/shadow/releases/download/%{version}/shadow-%{version}.tar.xz",
      },
    }
  in

  let shadow = {
    version | default = "4.19.4",
    source_object_hash | default = "ce57a313e315a0a7cb04a8f50cc20753e994e487bbe9b78a2a824ca75cb486c0",
    name = "shadow-%{version}",
    tag = "Autotools",
    deps = {
      # pkgconf is not among the default Autotools build deps, so it must be
      # listed explicitly (as must libxcrypt, PAM and the systemd dev headers).
      build = [
        pkgs.libxcrypt,
        pkgs.linux_pam,
        pkgs.pkgconf,
        pkgs.systemd_dev,
      ],
      # login/su/passwd link libpam and libcrypt; login's PAM stack loads the
      # pam modules from the full linux_pam package (usr/lib/security).
      runtime = [
        pkgs.glibc_libs,
        pkgs.libxcrypt_libs,
        pkgs.linux_pam,
      ],
    },
    config = {
      pre_configure = {
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
          # Additive install: writes land directly in the overlay root, so no
          # DESTDIR (the main install already used --prefix=/usr, no DESTDIR).
          m%"
            make -C man install-man
            rm -f /etc/pam.d/login
          "%,
        ],
      },
    },
    inputs = {
      source = shadow_src version source_object_hash,
    },
  }
  in

  {
    include [
      shadow,
    ],
  }
