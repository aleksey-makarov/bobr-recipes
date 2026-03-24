let shell_quote = fun value =>
  "'" ++ std.string.replace "'" "'\"'\"'" value ++ "'"
in

let render_args = fun args =>
  std.string.join " " (std.array.map shell_quote args)
in

let append_args = fun command args =>
  if args == [] then command else command ++ " " ++ render_args args
in

let ArgsContract = {
  configure_args | Array String | default = [],
  env | { _ | String } | default = {},
  pre_configure | String | default = "",
  post_install | String | default = "",
  ..
}
in

{
  autotools = fun cfg =>
    let cfg = cfg | ArgsContract in
    let configure_cmd =
      append_args ("./configure --prefix=" ++ shell_quote "/usr") cfg.configure_args
    in
    let env_block =
      let lines =
        std.array.map
          (fun key => "export " ++ key ++ "=" ++ shell_quote (std.record.get key cfg.env))
          (std.record.fields cfg.env)
      in
      if lines == [] then "" else "\n" ++ std.string.join "\n" lines
    in
    let pre_configure_block =
      if cfg.pre_configure == "" then "" else "\n" ++ cfg.pre_configure
    in
    let post_install_block =
      if cfg.post_install == "" then "" else "\n" ++ cfg.post_install
    in
    m%"
      #!/usr/bin/env bash
      set -euo pipefail

      src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
      out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

      cd "/in/${src}"
      %{env_block}
      if [ ! -x ./configure ]; then
        candidates=""
        for d in ./*; do
          if [ -d "$d" ] && [ -x "$d/configure" ]; then
            candidates="$candidates $d"
          fi
        done

        set -- $candidates
        if [ "$#" -eq 1 ]; then
          cd "$1"
        fi
      fi

      if [ ! -x ./configure ]; then
        echo "autotools build-script: ./configure not found in /in/${src}" >&2
        exit 1
      fi
      %{pre_configure_block}
      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      %{configure_cmd}
      make -j"$jobs"
      make DESTDIR="/out/${out}" install%{post_install_block}

    "%,
}
