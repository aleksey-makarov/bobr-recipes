let recipe = import "../recipe-lib.ncl" in
# krb5 -- MIT Kerberos 5. gnome-control-center's System panel hard-requires krb5
# (`dependency('krb5')` + assert). Autotools build; the configure script lives in
# the tarball's src/ subdirectory. Installs into merged-usr (sbin -> bin).
# Configure version and hash through `pkgs.krb5_src`.
fun pkgs =>
  let series = recipe.version_prefix 2 in

  let krb5_src = {
    version | default = "1.22.2",
    name = "krb5-src-%{version}",
    tag = "Source",
    object_hash | default = "3243ffbc8ea4d4ac22ddc7dd2a1dc54c57874c40648b60ff97009763554eaf13",
    origin = {
      tag = "Http",
      url = "https://kerberos.org/dist/krb5/%{series version}/krb5-%{version}.tar.gz",
    },
  }
  in

  let krb5 = {
    name = "krb5-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.bison,
        pkgs.perl,
        pkgs.openssl,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.openssl,
      ],
    },
    config = {
      source_subdir = "src",
      configure_args = [
        "--libdir=/usr/lib",
        "--sbindir=/usr/bin",
        "--disable-static",
        "--without-ldap",
        "--without-system-verto",
      ],
      # krb5 bundles com_err, which the base rootfs already provides (via
      # e2fsprogs). Drop the duplicated com_err dev/build files that would
      # collide on merge (headers, pkg-config, build tools, the unversioned .so
      # and static lib). krb5's own runtime libcom_err.so.3 (a different soname
      # from the base's .so.2) is kept so libkrb5 still resolves it.
      post_install = {
        name = "drop_bundled_com_err",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          "rm -f /usr/bin/compile_et /usr/bin/mk_cmds /usr/include/com_err.h /usr/lib/libcom_err.so /usr/lib/libcom_err.a /usr/lib/pkgconfig/com_err.pc /usr/share/man/man1/compile_et.1 /usr/share/man/man1/mk_cmds.1 /usr/share/man/man3/com_err.3; rm -rf /usr/include/et /usr/share/et",
        ],
      },
    },
    inputs = {
      source = pkgs.krb5_src,
    },
  }
  in

  {
    include [
      krb5_src,
      krb5
    ]
  }
