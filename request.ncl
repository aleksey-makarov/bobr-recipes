let mkPkgs = import "mk-pkgs.ncl" in
let recipe = import "recipe-lib.ncl" in
fun target_name =>
  let raw = mkPkgs [] in
  recipe.to_request (std.record.get target_name raw)
