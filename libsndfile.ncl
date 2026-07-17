# libsndfile -- library for reading/writing sampled-sound files. PulseAudio
# links it (even a client-only build). Autotools. Built minimal: the optional
# external codec libraries (FLAC/Ogg/Vorbis/Opus/mpg123) are absent from the
# build rootfs, so libsndfile auto-disables them and handles the core formats
# (WAV/AIFF/...) -- enough for PulseAudio's sound-file loading.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libsndfile_src = fun version =>
    fun hash =>
      {
        name = "libsndfile-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/libsndfile/libsndfile/releases/download/%{version}/libsndfile-%{version}.tar.xz",
        },
      }
  in

  let libsndfile = {
    version | default = "1.2.2",
    source_object_hash
      | default
      = "3799ca9924d3125038880367bf1468e53a1b7e3686a934f098b7e1d286cdb80e",
    name = "libsndfile-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.python,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        # libsndfile 1.2.2's bundled ALAC code uses `false`/`bool` as ordinary
        # identifiers, which gcc 15 rejects under its default C23 mode. Pin the
        # older language dialect where those are not keywords.
        "CFLAGS=-std=gnu17",
        "--disable-static",
        "--disable-external-libs",
        "--disable-mpeg",
      ],
    },
    inputs = {
      source = libsndfile_src version source_object_hash,
    },
  }
  in

  {
    include [
      libsndfile,
    ],
  }
