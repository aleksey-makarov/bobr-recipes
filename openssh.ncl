# OpenSSH (portable) -- provides sshd, ssh, ssh-keygen, scp, sftp. Autotools.
# PAM enabled (login sessions), privilege separation as user `sshd` in
# /var/empty, config under /etc/ssh. `make install` generates host keys into
# the DESTDIR; those are host identity, so post_install removes them -- they are
# regenerated on first boot by sshd-keygen.service (stateless model).
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "openssh-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-%{version}.tar.gz",
        },
      }
  in

  let openssh = {
    version | default = "10.4p1",
    source_object_hash | default = "ef6026dd2aea8d56059638d5d3262902c892ceba9f88395835e0d06d3fb63238",
    name = "openssh-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.openssl,
        pkgs.zlib,
        pkgs.linux_pam,
      ],
      runtime = [
        pkgs.glibc_libs,
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
        name = "drop_baked_host_keys",
        run_as = "root",
        cwd = "@{out}",
        argv = [
          "/bin/sh",
          "-ec",
          "rm -f \"@{out}\"/etc/ssh/ssh_host_*",
        ],
      },
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      openssh,
    ],
  }
