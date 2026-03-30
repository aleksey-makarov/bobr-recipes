fun pkgs =>
  let build_autotools_with =
    fun image =>
    fun { name, sources, script_config } =>
      store.bind (store.sequence sources) (fun sources =>
      store.bind pkgs.buildscript_autotools (fun script =>
      store.bind image (fun image =>
      store.binary name {
        kind = "binary-output",
        optimize = "size",
        include script_config,
      } image script sources)))
  in

  let build_autotools =
    build_autotools_with pkgs.build_image
  in

  let build_bootstrap_autotools =
    build_autotools_with pkgs.bootstrap_image
  in

  {
    include [
      build_autotools,
      build_bootstrap_autotools,
    ],
  }
