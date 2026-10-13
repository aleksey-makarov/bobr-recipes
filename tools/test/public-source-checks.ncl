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
let builder_from_goal = fun graph =>
  let rec go = fun id =>
    let node = std.record.get id graph.nodes in
    if std.record.has_field "source" node.inputs then
      node
    else if std.record.has_field "tree" node.inputs then
      go node.inputs.tree
    else
      std.fail_with "public Source test: lowered builder has neither source nor tree input"
  in go
in
let replace_version = fun previous =>
  fun version =>
    let rec replace = fun value =>
      if std.is_string value then
        std.string.replace previous version value
      else if std.is_array value then
        std.array.map replace value
      else if std.is_record value then
        std.record.map (fun _field entry => replace entry) value
      else
        value
    in replace
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
          let splits = std.array.filter (fun entry => std.record.has_field "split" entry.consumer) builders in
          let graph =
            recipe.to_request_goals
              { include recipes_path }
              pkgs
              (
                (std.array.map (fun spec => std.record.get spec.source pkgs) selected)
                @ std.array.map (fun entry => entry.node) builders
                @ std.array.map (fun entry => std.record.get entry.consumer.split.attr pkgs) splits
              )
          in
          let original_graph =
            recipe.to_request_goals
              { include recipes_path }
              original
              (std.array.map (fun entry => std.record.get entry.consumer.attr original) builders)
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
                  let version_url_parts_correct =
                    if mode == "version_hash" && std.record.has_field "version_url_parts" spec then
                      std.array.all
                        (fun part =>
                          std.array.any
                            (fun url => std.array.length (std.string.split part url) > 1)
                            urls
                        )
                        (spec.version_url_parts expected_version)
                    else
                      true
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
                      && std.array.all (fun url => std.string.is_match "9[._-]8[._-]7" url || std.string.is_match changed_hash url) urls
                      && version_url_parts_correct,
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
                      && (
                        let lowered = builder_from_goal graph (std.array.at (std.array.length selected + index) graph.goals) in
                        std.record.get lowered.inputs.source graph.nodes == wire entry.expected_source
                        && (
                          if std.record.has_field "docdir_prefix" entry.consumer then
                            let expected_arg = entry.consumer.docdir_prefix ++ entry.expected_source.version in
                            std.array.elem expected_arg entry.node.config.configure_args
                            && std.array.elem expected_arg lowered.config.script_config.configure_args
                          else
                            true
                        )
                        && (
                          if std.record.get_or "config_follows_source" false entry.consumer then
                            let previous = std.record.get entry.consumer.attr original in
                            let expected = replace_version previous.inputs.source.version entry.expected_source.version in
                            let expected =
                              if std.record.has_field "config_version_alias" entry.consumer then
                                let alias = entry.consumer.config_version_alias in
                                fun config => replace_version (alias previous.inputs.source.version) (alias entry.expected_source.version) (expected config)
                              else
                                expected
                            in
                            entry.node.config == expected previous.config
                            && lowered.config == expected (builder_from_goal original_graph (std.array.at index original_graph.goals)).config
                          else
                            true
                        )
                        && (
                          if std.record.has_field "rootfs_suffix" entry.consumer then
                            let expected_name = entry.node.name ++ entry.consumer.rootfs_suffix in
                            entry.node.inputs._rootfs.name == expected_name
                            && (std.record.get lowered.inputs._rootfs graph.nodes).name == expected_name
                          else
                            true
                        )
                      ),
                  }
              )
              builders
          in
          let split_checks =
            std.array.map_with_index
              (fun index =>
                fun entry =>
                  let split = std.record.get entry.consumer.split.attr pkgs in
                  let lowered = builder_from_goal graph (std.array.at (std.array.length selected + std.array.length builders + index) graph.goals) in
                  {
                    attr = entry.consumer.split.attr,
                    correct =
                      split.name == entry.consumer.split.name_prefix
                      ++ entry.expected_source.version
                      && split.inputs.tree.name == entry.node.name
                      && wire split.inputs.tree.inputs.source == wire entry.expected_source
                      && std.record.get lowered.inputs.source graph.nodes == wire entry.expected_source
                      && split.config == (std.record.get entry.consumer.split.attr original).config,
                  }
              )
              splits
          in
          let checks = source_checks @ builder_checks @ split_checks in
          {
            include mode,
            sources = std.array.length source_checks,
            builders = std.array.length builder_checks,
            splits = std.array.length split_checks,
            failures = std.array.filter (fun check => !check.correct) checks,
            passed = std.array.all (fun check => check.correct) checks,
          },
}
