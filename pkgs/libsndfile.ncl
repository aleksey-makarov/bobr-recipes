# libsndfile -- library for reading/writing sampled-sound files. PulseAudio
# links it (even a client-only build). Autotools. Built minimal: the optional
# external codec libraries (FLAC/Ogg/Vorbis/Opus/mpg123) are absent from the
# build rootfs, so libsndfile auto-disables them and handles the core formats
# (WAV/AIFF/...) -- enough for PulseAudio's sound-file loading.
# Configure version and hash through `pkgs.libsndfile_src`.
fun pkgs =>
  let libsndfile_src = {
    version | default = "1.2.2",
    name = "libsndfile-src-%{version}",
    tag = "Source",
    object_hash | default = "3799ca9924d3125038880367bf1468e53a1b7e3686a934f098b7e1d286cdb80e",
    origin = {
      tag = "Http",
      url = "https://github.com/libsndfile/libsndfile/releases/download/%{version}/libsndfile-%{version}.tar.xz",
    },
  }
  in

  let libsndfile = {
    name = "libsndfile-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.python,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libsndfile_src,
    },
  }
  in

  {
    include [
      libsndfile_src,
      libsndfile,
    ],
  }
