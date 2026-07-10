# SQLite (autoconf amalgamation). Needed by colord (it requires sqlite3 at
# configure even with the daemon off). Library only -- CLI readline off, no
# other deps. `version`/`hashes`/`year` are node fields (overridable), as in
# linux.ncl. sqlite's tarball URL embeds the release year and a packed version
# number X YY ZZ 00 (e.g. 3.53.3 -> 3530300), derived here.
let default_version = "3.53.3" in
let default_hashes = {
  "3.53.3" = "fbbc28e95d9ceb14507bb3524e4758da6a6cfed6cdb5614d7e889fdeae388479",
}
in
let default_year = "2026" in

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
    version | default = default_version,
    hashes | default = default_hashes,
    year | default = default_year,
    name = "sqlite-%{version}",
    tag = "Autotools",
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
      source = mk_src version year (hashes."%{version}"),
    },
  }
  in

  {
    include [
      sqlite,
    ],
  }
