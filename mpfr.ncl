fun _pkgs =>
  let mpfr_src_4_2_2 =
    store.fetch "mpfr-src-4.2.2" {
      url = [
        "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
      ],
      hash = "md5:7c32c39b8b6e3ae85f25156228156061",
    }
  in

  {
    include [mpfr_src_4_2_2],
  }
