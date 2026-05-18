# Exports `request`, a function `{ store_path, target_name, local_path? } -> Dyn`.
#
# Usage:
# - `request { store_path = "/abs/store", local_path = "/abs/local", target_name = "foo" }`
#   returns a full `mbuild` JSON request envelope for the selected package
#   attribute.
# - `local_path` is optional and is emitted as `paths.local` only when present.
#
# Arguments:
# - `store_path`: absolute path to the mbuild store root
# - `target_name`: package attribute name from `pkgs.ncl`
# - `local_path` (optional): absolute base path for local `Source` origins
#
# The returned value has this outer shape:
# - `paths.store = store_path`
# - `paths.local = local_path` when provided
# - `nodes = recipe.to_request raw (...)`
let mkPkgs = import "pkgs.ncl" in
let recipe = import "recipe-lib.ncl" in
let RequestArgs = {
  store_path | String,
  target_name | String,
  local_path | String | optional,
}
in
let request | RequestArgs -> Dyn = fun args =>
  let store_path = args.store_path in
  let target_name = args.target_name in
  let has_local_path = std.record.has_field "local_path" args in
  let local_path = if has_local_path then std.record.get "local_path" args else "" in
  let request_paths =
    { store = store_path }
    & (if has_local_path then { local = local_path } else {})
  in
  if !std.string.is_match "^/" store_path then
    std.fail_with "request.ncl: store_path must be an absolute path"
  else if has_local_path && !std.string.is_match "^/" local_path then
    std.fail_with "request.ncl: local_path must be an absolute path"
  else
    let raw = mkPkgs [] in
    {
      paths = request_paths,
      nodes = recipe.to_request raw (std.record.get target_name raw),
    }
in

request
