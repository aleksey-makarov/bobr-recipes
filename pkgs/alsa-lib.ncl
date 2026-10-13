# alsa-lib -- ALSA userspace library (libasound). gnome-settings-daemon asserts
# ALSA support is mandatory on Linux (its media-keys/sound plugin drives the
# mixer through ALSA even when PulseAudio is the sound server), so libasound is a
# hard dependency of gsd. Plain Autotools build with no external dependencies;
# the Python bindings and documentation are off.
# Configure version and hash through `pkgs.alsa_lib_src`.
fun pkgs =>
  let alsa_lib_src = {
    version | default = "1.2.14",
    name = "alsa-lib-src-%{version}",
    tag = "Source",
    object_hash | default = "be9c88a0b3604367dd74167a2b754a35e142f670292ae47a2fdef27a2ee97a32",
    origin = {
      tag = "Http",
      url = "https://www.alsa-project.org/files/pub/lib/alsa-lib-%{version}.tar.bz2",
    },
  }
  in

  let alsa_lib = {
    name = "alsa-lib-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-python",
      ],
    },
    inputs = {
      source = pkgs.alsa_lib_src,
    },
  }
  in

  {
    include [
      alsa_lib_src,
      alsa_lib,
    ],
  }
