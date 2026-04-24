# Exports `request`, a function `String -> String -> Dyn`.
#
# Usage:
# - `request store_path target_name`
#   returns a full `mbuild` JSON request envelope for the selected package
#   attribute.
#
# Arguments:
# - `store_path`: absolute path to the mbuild store root
# - `target_name`: package attribute name from `pkgs.ncl`
#
# The returned value has this outer shape:
# - `paths.store = store_path`
# - `nodes = recipe.to_request (...)`

let mkPkgs = import "pkgs.ncl" in
let recipe = import "recipe-lib.ncl" in
let request | String -> String -> Dyn =
  fun store_path =>
    fun target_name =>
      if std.string.is_match "^/" store_path then
        let raw = mkPkgs [] in
        {
          paths = {
            store = store_path,
          },
          nodes = recipe.to_request (std.record.get target_name raw),
        }
      else
        std.fail_with "request.ncl: store_path must be an absolute path"
in

request
