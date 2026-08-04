let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let xcompose_data_src = fun version => fun hash => {
    name = "xcompose-data-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://www.x.org/releases/individual/lib/libX11-%{version}.tar.xz",
    },
  }
  in

  # libxkbcommon uses the traditional X locale database for Compose sequences
  # even in a pure-Wayland process.  Build only that architecture-neutral data
  # from libX11; no X11 client library enters the runtime closure.
  let xcompose_data = {
    version | default = "1.8.13",
    source_object_hash | default =
      "69606f485c2c07c14ef64f75b7bb326d48587af33795d9ab3e607c0b5f94f11c",
    name = "xcompose-data-%{version}",
    tag = "SandboxInstallDeps",
    deps = {
      build = [
        pkgs.gcc,
        pkgs.coreutils,
        pkgs.findutils,
        pkgs.grep,
        pkgs.sed,
      ],
      runtime = [],
    },
    config = {
      script_config = {},
      steps = [
        recipe.prepare_source_step,
        {
          name = "install_compose_data",
          run_as = "root",
          cwd = "@{build}/source/nls",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              src=$PWD
              dest=/usr/share/X11/locale

              preprocess()
              {
                input=$1
                output=$2
                /usr/bin/cpp -traditional -undef -DWCHAR32=1 < "$input" \
                  | sed \
                      -e '/^#  *[0-9][0-9]*  *.*/d' \
                      -e '/^#line  *[0-9][0-9]*  *.*/d' \
                      -e '/^[[:space:]]*XCOMM$/s/XCOMM/#/' \
                      -e '/^[[:space:]]*XCOMM[^a-zA-Z0-9_]/s/XCOMM/#/' \
                      -e '/^[[:space:]]*XHASH/s/XHASH/#/' \
                      -e "s,X11_LOCALEDATADIR,$dest,g" \
                      -e '/@@$/s/@@$/\\/' \
                      -e '/^$/d' \
                  > "$output"
              }

              install -d "$dest/en_US.UTF-8"
              preprocess "$src/en_US.UTF-8/Compose.pre" \
                "$dest/en_US.UTF-8/Compose"

              for name in locale.alias compose.dir locale.dir; do
                preprocess "$src/$name.pre" "/tmp/$name.l1"
                sed \
                  -e '/^[^#][^[:space:]]*:/s/://' \
                  -e '/^[^#].*[[:space:]].*:/d' \
                  < "/tmp/$name.l1" > "/tmp/$name.l2"
                cat "/tmp/$name.l2" "/tmp/$name.l1" > "$dest/$name"
              done

              test -s "$dest/en_US.UTF-8/Compose"
              grep -Fq 'en_US.UTF-8/Compose:' "$dest/compose.dir"
              grep -Fq 'C.UTF-8:' "$dest/locale.alias"
              chmod 0444 \
                "$dest/en_US.UTF-8/Compose" \
                "$dest/locale.alias" \
                "$dest/compose.dir" \
                "$dest/locale.dir"
            "%,
          ],
        },
      ],
    },
    inputs = {
      source = xcompose_data_src version source_object_hash,
    },
  }
  in

  {
    include [xcompose_data],
  }
