let br = import "build-rootfs.ncl" in

fun pkgs =>
  let autoconf_src = fun version =>
    fun hash =>
    {
      name = "autoconf-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = [
          "https://ftp.gnu.org/gnu/autoconf/autoconf-%{version}.tar.xz",
          "https://mirrors.kernel.org/gnu/autoconf/autoconf-%{version}.tar.xz",
        ],
      },
    }
  in

  # Deps-derived build rootfs, replacing the curated system_rootfs_2: the native
  # toolchain plus perl (autoconf's scripts) and m4 (its macro processor).
  # autoconf is a default Autotools build dep but not a native-toolchain member,
  # so nothing in this closure pulls autoconf back in -- no gen1 substitution
  # needed (unlike bzip2/xz).
  let autoconf_build_rootfs =
    br.build_rootfs_closure
      pkgs
      "autoconf-build-rootfs"
      (br.native_build_deps pkgs @ [pkgs.perl, pkgs.m4])
  in

  let autoconf = {
    version | default = "2.73",
    source_object_hash | default = "9fd672b1c8425fac2fa67fa0477b990987268b90ff36d5f016dae57be0d6b52e",
    name = "autoconf-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {},
    inputs = {
      _rootfs = autoconf_build_rootfs,
      source = autoconf_src version source_object_hash,
    },
  }
  in

  {
    include [
      autoconf,
    ],
  }
