# p11-kit -- PKCS#11 module loader / trust store. gcr (linked by gnome-shell)
# needs the p11-kit-1 library. The release tarball is Autotools; it finds
# libtasn1 and libffi with pkg-config (hence pkgconf in the build deps).
# Configure version and hash through `pkgs.p11_kit_src`.
fun pkgs =>
  let p11_kit_src = {
    version | default = "0.26.4",
    name = "p11-kit-src-%{version}",
    tag = "Source",
    object_hash | default = "89c3ffb10e076ee036e14732bf6547a1e1c4fb48699a5dee7ceb5ce4f7c0c462",
    origin = {
      tag = "Http",
      url = "https://github.com/p11-glue/p11-kit/releases/download/%{version}/p11-kit-%{version}.tar.xz",
    },
  }
  in

  let p11_kit = {
    name = "p11-kit-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.libtasn1,
        pkgs.libffi,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libtasn1,
        pkgs.libffi,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-doc",
        "--without-systemd",
        # No default trust store to auto-detect yet; point the trust module at
        # the conventional system CA bundle location (populated once a
        # ca-certificates package lands).
        "--with-trust-paths=/etc/ssl/certs/ca-certificates.crt",
      ],
    },
    inputs = {
      source = pkgs.p11_kit_src,
    },
  }
  in

  {
    include [
      p11_kit_src,
      p11_kit,
    ],
  }
