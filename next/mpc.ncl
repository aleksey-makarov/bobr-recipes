fun _pkgs =>
  let mpc_src_1_3_1 =
    store.fetch "mpc-src-1.3.1" {
      url = [
        "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz",
      ],
      hash = "md5:5c9bc658c9fd0f940e8e3e0f09530c62",
    }
  in

  {
    include [mpc_src_1_3_1],
  }
