let shell_quote = fun value =>
  "'" ++ std.string.replace "'" "'\"'\"'" value ++ "'"
in

let render_args = fun args =>
  std.string.join " " (std.array.map shell_quote args)
in

let append_args = fun command args =>
  if args == [] then command else command ++ " " ++ render_args args
in

let concat_many = fun chunks =>
  std.array.fold_left std.array.concat [] chunks
in

let ArgsContract = {
  output | String,
  prefix | String | default = "/usr",
  configure | String | default = "./configure",
  configure_args | Array String | default = [],
  make | String | default = "make",
  make_args | Array String | default = [],
  install | String | default = "make",
  install_args | Array String | optional,
  env | { _ | String } | default = {},
  prepend_path | Array String | default = [],
  prepend_pkg_config_path | Array String | default = [],
  prepend_cflags | Array String | default = [],
  prepend_cppflags | Array String | default = [],
  prepend_ldflags | Array String | default = [],
  in_source | Bool | default = true,
  build_dir | String | default = "build",
  autoreconf | Bool | default = false,
  autoreconf_args | Array String | default = ["-fi"],
  pre_configure | String | default = "",
  post_install | String | default = "",
  ..
}
in

{
  autotools = fun cfg =>
    let cfg = cfg | ArgsContract in
    let configure_cmd =
      let configure_program =
        if cfg.in_source then
          cfg.configure
        else if cfg.configure == "./configure" then
          "../configure"
        else
          cfg.configure
      in
      append_args (configure_program ++ " --prefix=" ++ shell_quote cfg.prefix) cfg.configure_args
    in
    let make_cmd = append_args cfg.make cfg.make_args ++ " -j\"$jobs\"" in
    let install_cmd =
      if std.record.has_field "install_args" cfg then
        append_args cfg.install cfg.install_args
      else
        cfg.install ++ " DESTDIR=\"/out/${out}\" install"
    in
    let env_lines =
      std.array.map
        (fun key => "export " ++ key ++ "=" ++ shell_quote (std.record.get key cfg.env))
        (std.record.fields cfg.env)
    in
    let prepend_lines =
      std.array.concat
        (
          std.array.concat
            (
              if cfg.prepend_path == [] then
                []
              else
                [
                  "export PATH="
                  ++ shell_quote (std.string.join ":" cfg.prepend_path)
                  ++ ":\"${PATH:-}\"",
                ]
            )
            (
              if cfg.prepend_pkg_config_path == [] then
                []
              else
                [
                  "export PKG_CONFIG_PATH="
                  ++ shell_quote (std.string.join ":" cfg.prepend_pkg_config_path)
                  ++ ":\"${PKG_CONFIG_PATH:-}\"",
                ]
            )
        )
        (
          std.array.concat
            (
              if cfg.prepend_cflags == [] then
                []
              else
                [
                  "export CFLAGS="
                  ++ shell_quote (std.string.join " " cfg.prepend_cflags)
                  ++ "\"${CFLAGS:+ ${CFLAGS}}\"",
                ]
            )
            (
              std.array.concat
                (
                  if cfg.prepend_cppflags == [] then
                    []
                  else
                    [
                      "export CPPFLAGS="
                      ++ shell_quote (std.string.join " " cfg.prepend_cppflags)
                      ++ "\"${CPPFLAGS:+ ${CPPFLAGS}}\"",
                    ]
                )
                (
                  if cfg.prepend_ldflags == [] then
                    []
                  else
                    [
                      "export LDFLAGS="
                      ++ shell_quote (std.string.join " " cfg.prepend_ldflags)
                      ++ "\"${LDFLAGS:+ ${LDFLAGS}}\"",
                    ]
                )
            )
        )
    in
    let pre_lines = if cfg.pre_configure == "" then [] else [cfg.pre_configure] in
    let post_lines = if cfg.post_install == "" then [] else [cfg.post_install] in
    let base_lines = [
      "#!/usr/bin/env bash",
      "set -euo pipefail",
      "",
      "src=\"${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}\"",
      "out=\"${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}\"",
      "",
      "cd \"/in/${src}\"",
      "",
    ]
    in
    let configure_search_lines = [
      "if [ ! -x ./configure ]; then",
      "  candidates=\"\"",
      "  for d in ./*; do",
      "    if [ -d \"$d\" ] && [ -x \"$d/configure\" ]; then",
      "      candidates=\"$candidates $d\"",
      "    fi",
      "  done",
      "",
      "  set -- $candidates",
      "  if [ \"$#\" -eq 1 ]; then",
      "    cd \"$1\"",
      "  fi",
      "fi",
      "",
    ]
    in
    let autoreconf_lines =
      if cfg.autoreconf then
        [
          "if [ -x ./autogen.sh ]; then ./autogen.sh; fi",
          "if [ -x ./bootstrap ]; then ./bootstrap; fi",
          append_args "autoreconf" cfg.autoreconf_args,
          "",
        ]
      else
        []
    in
    let configure_check_lines = [
      "if [ ! -x ./configure ]; then",
      "  echo \"autotools build-script: ./configure not found in /in/${src}\" >&2",
      "  exit 1",
      "fi",
      "",
    ]
    in
    let build_dir_lines =
      if cfg.in_source then
        []
      else
        [
          "mkdir -p " ++ shell_quote cfg.build_dir,
          "cd " ++ shell_quote cfg.build_dir,
          "",
        ]
    in
    let build_lines = [
      "jobs=\"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)\"",
    ]
    in
    let command_lines = [
      configure_cmd,
      make_cmd,
      install_cmd,
    ]
    in
    std.string.join
      "\n"
      (concat_many [
        base_lines,
        prepend_lines,
        env_lines,
        configure_search_lines,
        autoreconf_lines,
        configure_check_lines,
        pre_lines,
        build_dir_lines,
        build_lines,
        command_lines,
        post_lines,
      ])
    ++ "\n",
}
