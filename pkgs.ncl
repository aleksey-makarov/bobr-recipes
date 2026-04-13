let mkPkgs = import "mk-pkgs.ncl" in
let recipe = import "recipe-lib.ncl" in
let raw = mkPkgs [] in
std.record.map (fun _ node => recipe.to_request node) raw
