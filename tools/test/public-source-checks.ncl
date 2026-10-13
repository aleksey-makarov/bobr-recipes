# Check raw wiring and targeted lowered graphs; never export the package set.
let recipe = import "../../recipe-lib.ncl" in
let package_set = import "../../bobrpkgs.ncl" in
let cases = import "public-source-cases.ncl" in
let original = package_set [] in
let changed_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in
let replacement_hash = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc" in
let fixture_origin = { tag = "Http", url = "https://example.invalid/source-fixture.tar.xz" } in
let wire = fun source =>
  { name = source.name, tag = source.tag, object_hash = source.object_hash }
  & (if std.record.has_field "origin" source then { origin = source.origin } else {})
in
let replacement = fun label =>
  fun version =>
    {
      include version,
      name = "fixture-%{label}",
      tag = "Source",
      object_hash = replacement_hash,
      origin = fixture_origin,
    }
in
let is_input_mode = fun mode => mode == "input_first" || mode == "input_last" || mode == "input_same_version" in
let selected_consumer = fun spec =>
  fun mode =>
    std.array.at (if mode == "input_last" then std.array.length spec.consumers - 1 else 0) spec.consumers
in
let input_replacement = fun spec =>
  fun mode =>
    let selected = selected_consumer spec mode in
    replacement selected.attr (if mode == "input_same_version" then (std.record.get spec.source original).version else "8.7.6")
in
let patch_case = fun mode =>
  fun prev =>
    fun spec =>
      let previous_source = std.record.get spec.source prev in
      if is_input_mode mode then
        let selected = selected_consumer spec mode in
        {
          field = selected.attr,
          value =
            std.record.get selected.attr prev
            & {
              inputs.source | force = input_replacement spec mode,
            }
        }
      else
        {
          field = spec.source,
          value =
            if mode == "version_hash" then
              previous_source & { version = "9.8.7", object_hash = changed_hash }
            else if mode == "hash" then
              previous_source & { object_hash = changed_hash }
            else if mode == "origin" then
              previous_source & { origin | force = fixture_origin }
            else if mode == "replacement" then
              replacement spec.source "8.7.6"
            else
              previous_source
        }
in
let pkgs_for = fun mode =>
  if mode == "default" then
    original
  else
    package_set [ fun _final => fun prev => std.record.from_array (std.array.map (patch_case mode prev) cases)]
in
let source_from_goal = fun graph =>
  let rec go = fun id =>
    let node = std.record.get id graph.nodes in
    if std.record.has_field "source" node.inputs then
      std.record.get node.inputs.source graph.nodes
    else if std.record.has_field "tree" node.inputs then
      go node.inputs.tree
    else
      std.fail_with "public Source test: lowered builder has neither source nor tree input"
  in go
in
{
  count = std.array.length cases,
  run = fun recipes_path =>
    fun mode =>
      fun begin =>
        fun end =>
          let pkgs = pkgs_for mode in
          let selected =
            std.array.map
              (fun entry => entry.spec)
              (
                std.array.filter
                  (fun entry => entry.index >= begin && entry.index < end)
                  (std.array.map_with_index (fun index => fun spec => { include index, include spec }) cases)
              )
          in
          let builders =
            std.array.flat_map
              (fun spec =>
                std.array.map
                  (fun consumer =>
                    {
                      include spec,
                      include consumer,
                      node = std.record.get consumer.attr pkgs,
                      expected_source =
                        if is_input_mode mode && consumer.attr == (selected_consumer spec mode).attr then
                          input_replacement spec mode
                        else
                          std.record.get spec.source pkgs,
                    }
                  )
                  spec.consumers
              )
              selected
          in
          let graph =
            recipe.to_request_goals
              { include recipes_path }
              pkgs
              (
                (std.array.map (fun spec => std.record.get spec.source pkgs) selected)
                @ std.array.map (fun entry => entry.node) builders
              )
          in
          let source_checks =
            std.array.map_with_index
              (fun index =>
                fun spec =>
                  let source = std.record.get spec.source pkgs in
                  let previous = std.record.get spec.source original in
                  let expected_version =
                    if mode == "version_hash" then
                      "9.8.7"
                    else if mode == "replacement" then "8.7.6" else previous.version
                  in
                  let expected_hash =
                    if mode == "version_hash" || mode == "hash" then
                      changed_hash
                    else if mode == "replacement" then replacement_hash else previous.object_hash
                  in
                  let expected_name =
                    if mode == "replacement" then
                      "fixture-%{spec.source}"
                    else
                      spec.source_prefix ++ expected_version
                  in
                  let urls =
                    if mode == "version_hash" then
                      (if std.is_string source.origin.url then [source.origin.url] else source.origin.url)
                    else
                      []
                  in
                  let hash_only_origin =
                    previous.origin
                    & {
                      url | force =
                        if std.is_string previous.origin.url then
                          std.string.replace previous.object_hash changed_hash previous.origin.url
                        else
                          std.array.map (std.string.replace previous.object_hash changed_hash) previous.origin.url,
                    }
                  in
                  {
                    attr = spec.source,
                    correct =
                      source.tag == "Source"
                      && source.version == expected_version
                      && source.object_hash == expected_hash
                      && source.name == expected_name
                      && std.record.get (std.array.at index graph.goals) graph.nodes == wire source
                      && (if mode == "origin" || mode == "replacement" then source.origin == fixture_origin else true)
                      && (if mode == "hash" then source.origin == hash_only_origin else true)
                      && (if mode == "default" || is_input_mode mode then wire source == wire previous else true)
                      && std.array.all (fun url => std.string.is_match "9[._-]8[._-]7" url || std.string.is_match changed_hash url) urls,
                  }
              )
              selected
          in
          let builder_checks =
            std.array.map_with_index
              (fun index =>
                fun entry =>
                  {
                    attr = entry.consumer.attr,
                    correct =
                      !std.record.has_field "version" entry.node
                      && !std.record.has_field "source_object_hash" entry.node
                      && entry.node.name == entry.consumer.name_prefix
                      ++ entry.expected_source.version
                      && entry.node.inputs.source.version == entry.expected_source.version
                      && wire entry.node.inputs.source == wire entry.expected_source
                      && source_from_goal graph (std.array.at (std.array.length selected + index) graph.goals) == wire entry.expected_source,
                  }
              )
              builders
          in
          let checks = source_checks @ builder_checks in
          {
            include mode,
            sources = std.array.length source_checks,
            builders = std.array.length builder_checks,
            failures = std.array.filter (fun check => !check.correct) checks,
            passed = std.array.all (fun check => check.correct) checks,
          },
}
