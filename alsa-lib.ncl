# alsa-lib -- ALSA userspace library (libasound). gnome-settings-daemon asserts
# ALSA support is mandatory on Linux (its media-keys/sound plugin drives the
# mixer through ALSA even when PulseAudio is the sound server), so libasound is a
# hard dependency of gsd. Plain Autotools build with no external dependencies;
# the Python bindings and documentation are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let alsa_lib_src = fun version =>
    fun hash =>
      {
        name = "alsa-lib-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.alsa-project.org/files/pub/lib/alsa-lib-%{version}.tar.bz2",
        },
      }
  in

  let alsa_lib = {
    version | default = "1.2.14",
    source_object_hash
      | default
      = "be9c88a0b3604367dd74167a2b754a35e142f670292ae47a2fdef27a2ee97a32",
    name = "alsa-lib-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-python",
      ],
    },
    inputs = {
      source = alsa_lib_src version source_object_hash,
    },
  }
  in

  {
    include [
      alsa_lib,
    ],
  }
