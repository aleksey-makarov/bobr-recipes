# OpenSSH (portable) -- provides sshd, ssh, ssh-keygen, scp, sftp. Autotools.
# PAM enabled (login sessions), privilege separation as user `sshd` in
# /var/empty, config under /etc/ssh. `make install` generates host keys into
# the DESTDIR; those are host identity, so post_install removes them -- they are
# regenerated every boot by sshd-keygen.service (stateless model). post_install
# also prepends an `Include /etc/ssh/sshd_config.d/*.conf` line to the shipped
# sshd_config so the image can drop in policy (system-runtime-files provides
# 10-stateless.conf); prepended because sshd uses the first value per keyword.
# Configure version and hash through `pkgs.openssh_src`.
fun pkgs =>
  let openssh_src = {
    version | default = "10.4p1",
    name = "openssh-src-%{version}",
    tag = "Source",
    object_hash | default = "ef6026dd2aea8d56059638d5d3262902c892ceba9f88395835e0d06d3fb63238",
    origin = {
      tag = "Http",
      url = "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-%{version}.tar.gz",
    },
  }
  in

  let openssh = {
    name = "openssh-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libxcrypt,
        pkgs.openssl,
        pkgs.zlib,
        pkgs.linux_pam,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libxcrypt_libs,
        pkgs.openssl_libs,
        pkgs.zlib,
        pkgs.linux_pam_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        # usrmerge: /usr/sbin is a symlink to bin, so sshd must land in
        # /usr/bin (as every other recipe does) or TreeMerge conflicts.
        "--sbindir=/usr/bin",
        "--sysconfdir=/etc/ssh",
        "--with-pam",
        "--with-privsep-path=/var/empty",
        "--with-privsep-user=sshd",
      ],
      post_install = {
        name = "prepare_ssh_config",
        run_as = "root",
        cwd = "/",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            rm -f /etc/ssh/ssh_host_*
            cfg="/etc/ssh/sshd_config"
            if [ -f "$cfg" ]; then
              printf 'Include /etc/ssh/sshd_config.d/*.conf\n' \
                | cat - "$cfg" > "$cfg.new" && mv "$cfg.new" "$cfg"
            fi
          "%,
        ],
      },
    },
    inputs = {
      source = pkgs.openssh_src,
    },
  }
  in

  {
    include [
      openssh_src,
      openssh,
    ],
  }
