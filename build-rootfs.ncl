# Shared build-rootfs closure machinery. A build rootfs is `base_filesystem`
# plus the runtime closure of the given build deps -- assembled per build, with
# no curated `system_rootfs_X` snapshot. Used by the synthetic builders
# (synthetic/registry.ncl) and, via recipe-lib's `native_build_rootfs`, by
# custom multi-step recipes that would otherwise reach for system_rootfs_2.
#
# Leaf module: imports nothing from recipe-lib/registry (avoids an import cycle),
# so it carries its own copies of a few trivial helpers. The exported record uses
# `include` so its field names take the outer bindings (a plain `x = x` would
# self-reference in Nickel's recursive records).
let record_get_or = fun field =>
  fun fallback =>
    fun record =>
      if std.record.has_field field record then
        std.record.get field record
      else
        fallback
in
let fail = fun message =>
  std.record.get message {}
in
let pad3 = fun n =>
  let digits = std.string.from_number n in
  if n < 10 then
    "00" ++ digits
  else if n < 100 then
    "0" ++ digits
  else
    digits
in
let numbered_inputs = fun inputs =>
  std.record.from_array (
    std.array.map_with_index
      (fun idx =>
        fun input =>
          {
            field = "n" ++ pad3 idx,
            value = input,
          }
      )
      inputs
  )
in
let deps_or_empty = fun node =>
  record_get_or "deps" { build = [], runtime = [] } node
in
let runtime_deps_or_empty = fun node =>
  record_get_or "runtime" [] (deps_or_empty node)
in
let build_deps_or_empty = fun node =>
  record_get_or "build" [] (deps_or_empty node)
in
let dependency_cycle_error = fun stack =>
  fun name =>
    fail (
      "runtime dependency cycle: "
      ++ std.string.join " -> " (stack @ [name])
    )
in
let runtime_closure_set = fun roots =>
  let rec visit = fun visiting =>
    fun visited =>
      fun stack =>
        fun node =>
          let name = node.name in
          if std.record.has_field name visiting then
            dependency_cycle_error stack name
          else if std.record.has_field name visited then
            visited
          else
            let visiting_with_node = std.record.insert name true visiting in
            let visited_with_deps =
              std.array.fold_left
                (fun acc =>
                  fun dep =>
                    visit visiting_with_node acc (stack @ [name]) dep
                )
                visited
                (runtime_deps_or_empty node)
            in
            std.record.insert name node visited_with_deps
  in
  std.array.fold_left
    (fun acc => fun node => visit {} acc [] node)
    {}
    roots
in
let sorted_closure_nodes = fun closure_set =>
  # `std.record.fields` already returns names sorted; avoid Nickel's quadratic
  # `std.array.sort` (a few hundred names take tens of seconds).
  std.array.map
    (fun name => std.record.get name closure_set)
    (std.record.fields closure_set)
in
# The default native C/C++ build toolchain every native build needs.
let native_build_deps = fun pkgs => [
  pkgs.linux_headers,
  pkgs.glibc,
  pkgs.binutils,
  pkgs.gcc,
  pkgs.bash,
  pkgs.make,
  pkgs.coreutils,
  pkgs.gawk,
  pkgs.sed,
  pkgs.grep,
  pkgs.tar,
  pkgs.gzip,
  pkgs.bzip2,
  pkgs.xz,
  pkgs.patch,
  pkgs.findutils,
  pkgs.diffutils,
]
in
# The default build deps every Meson package needs: the native toolchain plus
# pkgconf and python. Shared so both the Meson package builder and recipes that
# assemble their own build rootfs (the glib bootstrap) use one list.
let meson_build_deps = fun pkgs =>
  native_build_deps pkgs
  @ [
    pkgs.pkgconf,
    pkgs.python,
  ]
in
# base_filesystem + runtime closure of `build_deps`, as a TreeMerge named
# `name`. If there are no deps, just the base skeleton.
let build_rootfs_closure = fun pkgs =>
  fun name =>
    fun build_deps =>
      let build_base = pkgs.base_filesystem in
      let closure_nodes = sorted_closure_nodes (runtime_closure_set build_deps) in
      if std.array.length closure_nodes == 0 then
        build_base
      else
        {
          include name,
          tag = "TreeMerge",
          config = {},
          inputs = numbered_inputs ([build_base] @ closure_nodes),
        }
in
# Like build_rootfs_closure, but after computing the runtime closure of
# `build_deps` it substitutes one node for another: every occurrence of
# `from_node` is dropped and `to_node`'s closure is merged in. Used by the glib
# bootstrap: glib and gobject-introspection declare honest deps on the final
# glib (so the image closure ships the final glib, never gen1), but their own
# build rootfs must use glib_gen1 instead -- otherwise the final glib would end
# up in its own build rootfs (a build cycle). Overlapping nodes are identical
# recipes, so the first-seen copy is kept.
let build_rootfs_closure_substituting = fun pkgs =>
  fun name =>
    fun build_deps =>
      fun from_node =>
        fun to_node =>
          let build_base = pkgs.base_filesystem in
          let raw = runtime_closure_set build_deps in
          let without_from =
            if std.record.has_field from_node.name raw then
              std.record.remove from_node.name raw
            else
              raw
          in
          let to_closure = runtime_closure_set [to_node] in
          let merged =
            std.array.fold_left
              (fun acc =>
                fun nm =>
                  if std.record.has_field nm acc then
                    acc
                  else
                    std.record.insert nm (std.record.get nm to_closure) acc
              )
              without_from
              (std.record.fields to_closure)
          in
          let closure_nodes = sorted_closure_nodes merged in
          {
            include name,
            tag = "TreeMerge",
            config = {},
            inputs = numbered_inputs ([build_base] @ closure_nodes),
          }
in
{
  include [
    build_deps_or_empty,
    runtime_closure_set,
    sorted_closure_nodes,
    native_build_deps,
    meson_build_deps,
    build_rootfs_closure,
    build_rootfs_closure_substituting,
  ],
  # Convenience for custom recipes: base_filesystem + closure of the native
  # toolchain plus `extra_deps`, named `name`. No system_rootfs_X.
  native_build_rootfs = fun pkgs =>
    fun name =>
      fun extra_deps =>
        build_rootfs_closure pkgs name (native_build_deps pkgs @ extra_deps),
}
