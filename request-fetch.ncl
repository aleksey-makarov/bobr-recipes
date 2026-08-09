# Lowers these recipes into a `bobr-fetch` request: the sources reachable from
# one target, flattened, plus the run identity and the connection limits.
#
# This is deliberately not `request.ncl`: the contract between the fetcher and
# the build is the store, not the request, so the two lowerings are free to
# differ -- and they do. The build needs the node graph and `jobs`; the fetcher
# needs a flat source list and limits. If the two are lowered from different
# checkouts and disagree, the build reports the missing object by name; nothing
# diverges silently, because an object either carries the declared hash or it
# does not.
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
# - `fetch`: optional connection limits, shaped like the profile's `fetch`
#   section; zero/empty fields are left out of the request so the fetcher
#   applies its own defaults
let mkPkgs = import "recipe-set.ncl" in
let fetch_schema = import "fetch-request-schema.ncl" in
let recipe = import "recipe-lib.ncl" in
let RequestArgs = {
  store_path | String,
  logs_path | String,
  work_path | String,
  run_id | String,
  recipes_path | String,
  target_name | String,
  overlays | Array Dyn | default = [],
  fetch
    | {
      per_host_default | Number | default = 0,
      per_host | { _ : Number } | default = {},
      max_connections | Number | default = 0,
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
      "request-fetch.ncl: %{(std.array.first relative).label} must be an absolute path"
  else if !std.string.is_match "^[A-Za-z0-9][A-Za-z0-9._-]*$" run_name then
    std.fail_with
      "request-fetch.ncl: run_id must start with a letter or digit and may contain only letters, digits, '.', '_', and '-'"
  else
    let raw = mkPkgs args.overlays in
    if !std.record.has_field target_name raw then
      std.fail_with
        "request-fetch.ncl: no recipe named '%{target_name}'; list what there is with bin/bobr-list-pkgs.sh"
    else
      let request_limits =
        (
          if args.fetch.per_host_default > 0 then
            { per_host_default = args.fetch.per_host_default }
          else
            {}
        )
        & (
          if args.fetch.max_connections > 0 then
            { max_connections = args.fetch.max_connections }
          else
            {}
        )
        & (
          if args.fetch.per_host == {} then
            {}
          else
            { per_host = args.fetch.per_host }
        )
      in
      {
        schema = fetch_schema,
        store = store_path,
        logs = logs_path,
        work = work_path,
        run_id = run_name,
        limits = request_limits,
        sources =
          recipe.to_fetch_sources
            { include recipes_path }
            raw
            (std.record.get target_name raw),
      }
in

request
