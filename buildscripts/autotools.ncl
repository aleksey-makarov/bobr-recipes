fun pkgs =>
  let buildscript_autotools =
    store.text "buildscript-autotools" {
      kind = "build-script",
      source = import "autotools.sh" as 'Text,
    }
  in

  {
    include [
      buildscript_autotools,
    ],
  }
