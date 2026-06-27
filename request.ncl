# Exports `request`, a function
# `{ store_path, recipes_path, target_name, overlays? } -> Dyn`.
#
# Usage:
# - `request { store_path = "/abs/store", recipes_path = "/abs/recipes", target_name = "foo" }`
#   returns a full `bobr` JSON request envelope for the selected package
#   attribute.
#
# Arguments:
# - `store_path`: absolute path to the bobr store root
# - `recipes_path`: absolute path to the bobr-recipes checkout root
# - `target_name`: package attribute name from `pkgs.ncl`
# - `overlays`: optional array of `pkgs.ncl` overlays
#
# The returned value has this outer shape:
# - `schema = "bobr-request-v1"`
# - `store = store_path`
# - `nodes = recipe.to_request { recipes_path } raw (...)`
let mkPkgs = import "pkgs.ncl" in
let recipe = import "recipe-lib.ncl" in
let RequestArgs = {
  store_path | String,
  recipes_path | String,
  target_name | String,
  overlays | Array Dyn | default = [],
}
in
let request | RequestArgs -> Dyn = fun args =>
  let store_path = args.store_path in
  let recipes_path = args.recipes_path in
  let target_name = args.target_name in
  if !std.string.is_match "^/" store_path then
    std.fail_with "request.ncl: store_path must be an absolute path"
  else if !std.string.is_match "^/" recipes_path then
    std.fail_with "request.ncl: recipes_path must be an absolute path"
  else
    let raw = mkPkgs args.overlays in
    {
      schema = "bobr-request-v1",
      store = store_path,
      nodes = recipe.to_request { include recipes_path } raw (std.record.get target_name raw),
    }
in

request
