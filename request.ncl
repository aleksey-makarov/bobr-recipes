# Exports `request`, a function
# `{ store_path, logs_path, work_path, run_id, recipes_path, pkgs, goals } -> Dyn`.
#
# Usage:
# - `request { store_path = "/abs/store", logs_path = "/abs/logs/run",
#     work_path = "/abs/work/run", run_id = "run", recipes_path = "/abs/recipes",
#     pkgs, goals = [pkgs.foo] }`
#   returns a full `bobr` JSON request envelope for the selected recipe values.
#
# Arguments:
# - `store_path`: absolute path to the bobr store root
# - `logs_path`: absolute path to this run's log directory (must exist)
# - `work_path`: absolute path to this run's work directory (must exist, and be
#   on the store's filesystem)
# - `run_id`: name of this run, recorded in the objects it produces
# - `recipes_path`: absolute path to the bobr-recipes checkout root
# - `pkgs`: final package set used to lower synthetic recipes
# - `goals`: non-empty ordered array of recipe values from that package set
#
# `bobr` neither names the run nor creates its directories: whoever invokes it
# does both (see bin/bobr-build.sh).
#
# The returned value has this outer shape:
# - `schema` from `request-schema.ncl`
# - `store = store_path`, `logs = logs_path`, `work = work_path`, `run_id`
# - ordered `goals`, acquisition `limits`, normalized `secondaries`
# - `nodes` and `goals` lowered from the selected recipe values
let request_schema = import "request-schema.ncl" in
let recipe = import "recipe-lib.ncl" in
let profile_contracts = import "build-profile/build-profile.ncl" in
let RequestArgs = {
  store_path | String,
  logs_path | String,
  work_path | String,
  run_id | String,
  recipes_path | String,
  pkgs | Dyn,
  goals | Array Dyn,
  progress | profile_contracts.ProgressPolicy | default = { mode = "auto" },
  limits
    | {
      per_host_default | Number | default = 0,
      per_host | { _ : Number } | default = {},
      max_connections | Number | default = 0,
      max_local_jobs | Number | default = 0,
    }
    | default
    = {},
  secondaries
    | {
      repository_cache | String | default = "",
      providers
        | Array profile_contracts.SecondaryProvider
        | default
        = [],
    }
    | default
    = {},
}
in
let request | RequestArgs -> Dyn = fun args =>
  let store_path = args.store_path in
  let logs_path = args.logs_path in
  let work_path = args.work_path in
  let run_name = args.run_id in
  let recipes_path = args.recipes_path in
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
    std.fail_with "request.ncl: %{(std.array.first relative).label} must be an absolute path"
  else if !std.string.is_match "^[A-Za-z0-9][A-Za-z0-9._-]*$" run_name then
    std.fail_with "request.ncl: run_id must start with a letter or digit and may contain only letters, digits, '.', '_', and '-'"
  else
    let lowered_graph = recipe.to_request_goals { include recipes_path } args.pkgs args.goals in
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
    let normalize_provider = fun raw_provider =>
      let provider = profile_contracts.validate_secondary_provider raw_provider in
      let has_local = std.record.has_field "local" provider in
      let backend_path =
        if has_local then
          provider.local.store
        else
          std.array.first provider.remote.trusted_keys
      in
      if !std.string.is_match "^/" backend_path then
        std.fail_with "request.ncl: secondary provider '%{provider.name}' paths must be absolute"
      else if !has_local
      && std.array.length (
        std.array.filter
          (fun path => !std.string.is_match "^/" path)
          provider.remote.trusted_keys
      ) != 0 then
        std.fail_with "request.ncl: remote provider '%{provider.name}' trusted-key paths must be absolute"
      else if !has_local
      && provider.remote.ca_bundle != ""
      && !std.string.is_match "^/" provider.remote.ca_bundle then
        std.fail_with "request.ncl: remote provider '%{provider.name}' CA bundle path must be absolute"
      else
        let remote_backend =
          {
            kind = "remote",
            master_url = provider.remote.master_url,
            trusted_keys = provider.remote.trusted_keys,
          }
          & (
            if provider.remote.ca_bundle == "" then
              {}
            else
              { ca_bundle = provider.remote.ca_bundle }
          )
        in
        let mapping_backend =
          if has_local then
            { kind = "local", store = provider.local.store }
          else
            remote_backend
        in
        let content_backend =
          if has_local then
            {
              kind = "local",
              store = provider.local.store,
              transfer = provider.local.transfer,
            }
          else
            remote_backend
        in
        (
          if provider.mappings then
            [
              {
                name = provider.name,
                capability = "mappings",
                backend = mapping_backend,
              }
            ]
          else
            []
        )
        @ (
          if provider.content then
            [
              {
                name = provider.name,
                capability = "content",
                backend = content_backend,
              }
            ]
          else
            []
        )
    in
    let resolved_repository_cache =
      if args.secondaries.repository_cache == "" then
        store_path ++ "/repository-cache"
      else
        args.secondaries.repository_cache
    in
    if !std.string.is_match "^/" resolved_repository_cache then
      std.fail_with "request.ncl: repository_cache must be an absolute path"
    else
      {
        schema = request_schema,
        store = store_path,
        logs = logs_path,
        work = work_path,
        run_id = run_name,
        goals = lowered_graph.goals,
        progress = args.progress,
        limits = request_limits,
        secondaries = {
          repository_cache = resolved_repository_cache,
          providers =
            std.array.flatten (
              std.array.map normalize_provider args.secondaries.providers
            ),
        },
        nodes = lowered_graph.nodes,
      }
in

request
