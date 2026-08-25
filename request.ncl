# Exports `request`, a function
# `{ store_path, logs_path, work_path, run_id, recipes_path, target_name, overlays? } -> Dyn`.
#
# Usage:
# - `request { store_path = "/abs/store", logs_path = "/abs/logs/run",
#     work_path = "/abs/work/run", run_id = "run", recipes_path = "/abs/recipes",
#     target_name = "foo" }`
#   returns a full `bobr` JSON request envelope for the selected package
#   attribute.
#
# Arguments:
# - `store_path`: absolute path to the bobr store root
# - `logs_path`: absolute path to this run's log directory (must exist)
# - `work_path`: absolute path to this run's work directory (must exist, and be
#   on the store's filesystem)
# - `run_id`: name of this run, recorded in the objects it produces
# - `recipes_path`: absolute path to the bobr-recipes checkout root
# - `target_name`: recipe attribute name from `recipe-set.ncl`
# - `overlays`: optional array of `recipe-set.ncl` overlays
#
# `bobr` neither names the run nor creates its directories: whoever invokes it
# does both (see bin/bobr-build.sh).
#
# The returned value has this outer shape:
# - `schema` from `request-schema.ncl`
# - `store = store_path`, `logs = logs_path`, `work = work_path`, `run_id`
# - ordered `goals`, acquisition `limits`, local `secondaries`
# - `nodes = recipe.to_request { recipes_path } raw (...)`
let mkPkgs = import "recipe-set.ncl" in
let request_schema = import "request-schema.ncl" in
let recipe = import "recipe-lib.ncl" in
let profile_contracts = import "build-profile.ncl" in
let RequestArgs = {
  store_path | String,
  logs_path | String,
  work_path | String,
  run_id | String,
  recipes_path | String,
  target_name | String,
  overlays | Array Dyn | default = [],
  progress | profile_contracts.ProgressPolicy | default = { mode = "auto" },
  limits
    | {
      per_host_default | Number | default = 0,
      per_host | { _ : Number } | default = {},
      max_connections | Number | default = 0,
      max_local_jobs | Number | default = 0,
    }
    | default = {},
  secondaries
    | {
      trusted_indexes | Array Dyn | default = [],
      content_sources | Array Dyn | default = [],
    }
    | default = {},
}
in
let request | RequestArgs -> Dyn = fun args =>
  let store_path = args.store_path in
  let logs_path = args.logs_path in
  let work_path = args.work_path in
  let run_name = args.run_id in
  let recipes_path = args.recipes_path in
  let target_name = args.target_name in
  let absolute_paths = [
    { label = "store_path", value = store_path },
    { label = "logs_path", value = logs_path },
    { label = "work_path", value = work_path },
    { label = "recipes_path", value = recipes_path },
  ]
  in
  let relative =
    std.array.filter (fun entry => !std.string.is_match "^/" entry.value) absolute_paths
  in
  if std.array.length relative != 0 then
    std.fail_with
      "request.ncl: %{(std.array.first relative).label} must be an absolute path"
  else if !std.string.is_match "^[A-Za-z0-9][A-Za-z0-9._-]*$" run_name then
    std.fail_with
      "request.ncl: run_id must start with a letter or digit and may contain only letters, digits, '.', '_', and '-'"
  else
    let raw = mkPkgs args.overlays in
    if !std.record.has_field target_name raw then
      std.fail_with
        "request.ncl: no recipe named '%{target_name}'; list what there is with bin/bobr-list-pkgs.sh"
    else
    let request_limits =
      (
        if args.limits.per_host_default > 0 then
          { per_host_default = args.limits.per_host_default }
        else
          {}
      )
      & (
        if args.limits.max_connections > 0 then
          { max_connections = args.limits.max_connections }
        else
          {}
      )
      & (
        if args.limits.max_local_jobs > 0 then
          { max_local_jobs = args.limits.max_local_jobs }
        else
          {}
      )
      & (
        if args.limits.per_host == {} then
          {}
        else
          { per_host = args.limits.per_host }
      )
    in
    {
      schema = request_schema,
      store = store_path,
      logs = logs_path,
      work = work_path,
      run_id = run_name,
      goals = ["root"],
      progress = args.progress,
      limits = request_limits,
      secondaries = args.secondaries,
      nodes = recipe.to_request { include recipes_path } raw (std.record.get target_name raw),
    }
in

request
