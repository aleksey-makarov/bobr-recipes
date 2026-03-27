fun pkgs =>
  let build_autotools =
    fun { name, sources, script_config } =>
      store.bind (store.sequence sources) (fun sources =>
      store.bind pkgs.buildscript_autotools (fun script =>
      store.bind pkgs.build_image (fun image =>
      store.binary name {
        kind = "binary-output",
        optimize = "size",
        include script_config,
      } image script sources)))
  in

  {
    include [
      build_autotools,
    ],
  }
