# SQLite (autoconf amalgamation). Needed by colord (it requires sqlite3 at
# configure even with the daemon off). Library only -- CLI readline off, no
# other deps. `version`/`source_object_hash`/`year` are node fields (overridable), as in
# linux.ncl. sqlite's tarball URL embeds the release year and a packed version
# number X YY ZZ 00 (e.g. 3.53.3 -> 3530300), derived here.

let pad2 = fun s => if std.string.length s == 1 then "0%{s}" else s in
let autoconf_num = fun version =>
  let p = std.string.split "." version in
  "%{std.array.at 0 p}%{pad2 (std.array.at 1 p)}%{pad2 (std.array.at 2 p)}00"
in

fun pkgs =>
  let mk_src = fun version =>
    fun year =>
      fun hash =>
        {
          name = "sqlite-src-%{version}",
          tag = "Source",
          object_hash = hash,
          origin = {
            tag = "Http",
            url = "https://www.sqlite.org/%{year}/sqlite-autoconf-%{autoconf_num version}.tar.gz",
          },
        }
  in

  let sqlite = {
    version | default = "3.53.3",
    source_object_hash | default = "c917d7db16648ec95f714974ace5e5dcf46b7dc70e26600a0a102a3141125db0",
    year | default = "2026",
    name = "sqlite-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--disable-readline",
      ],
    },
    inputs = {
      source = mk_src version year source_object_hash,
    },
  }
  in

  {
    include [
      sqlite,
    ],
  }
