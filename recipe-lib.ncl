{
  install = {
    root_default_attrs = {
      uid = 0,
      gid = 0,
      directory_mode = 0o755,
      regular_file_mode = 0o644,
      executable_file_mode = 0o755,
      symlink_mode = 0o777,
    },

    rule = fun path => fun attrs => { path, attrs },

    root_default_rule =
      let default_attrs = {
        uid = 0,
        gid = 0,
        directory_mode = 0o755,
        regular_file_mode = 0o644,
        executable_file_mode = 0o755,
        symlink_mode = 0o777,
      }
      in
      { path = "**", attrs = default_attrs },
  },

  to_request =
    fun root_node =>
      let rec collect =
        fun seen =>
        fun node =>
          if std.record.has_field node.name seen then
            seen
          else
            let seen_with_node = std.record.insert node.name node seen in
            std.array.fold_left
              (
                fun acc =>
                fun slot_name =>
                  let input = std.record.get slot_name node.inputs in
                  if input == null then
                    acc
                  else if std.is_array input then
                    std.array.fold_left
                      (fun inner_acc child => collect inner_acc child)
                      acc
                      input
                  else
                    collect acc input
              )
              seen_with_node
              (std.record.fields node.inputs)
      in

      let unique_nodes = collect {} root_node in
      let root_name = root_node.name in
      let other_names =
        std.array.sort
          std.string.compare
          (
            std.array.filter
              (fun name => name != root_name)
              (std.record.fields unique_nodes)
          )
      in
      let ordered_names = [root_name] @ other_names in
      let name_to_id =
        std.record.from_array
          (
            [{ field = root_name, value = "root" }] @
            std.array.map_with_index
              (
                fun idx =>
                fun name => {
                  field = name,
                  value = "n" ++ std.string.from_number idx,
                }
              )
              other_names
          )
      in
      let input_to_id =
        fun input =>
          if input == null then
            null
          else if std.is_array input then
            std.array.map
              (fun child => std.record.get child.name name_to_id)
              input
          else
            std.record.get input.name name_to_id
      in
      std.record.from_array
        (
          std.array.map
            (
              fun name =>
                let node = std.record.get name unique_nodes in
                {
                  field = std.record.get name name_to_id,
                  value = {
                    name = node.name,
                    tag = node.tag,
                    config = node.config,
                    inputs =
                      std.record.map
                        (fun _ input => input_to_id input)
                        node.inputs,
                  },
                }
            )
            ordered_names
        ),

  fetch = fun recipe_name => fun recipe_config => {
    name = recipe_name,
    tag = "Fetch",
    config = recipe_config,
    inputs = {},
  },

  text = fun recipe_name => fun recipe_config => {
    name = recipe_name,
    tag = "Text",
    config = recipe_config,
    inputs = {},
  },

  tree = fun recipe_name => fun recipe_config => {
    name = recipe_name,
    tag = "Tree",
    config = recipe_config,
    inputs = {},
  },

  container_image = fun recipe_name => fun recipe_config => {
    name = recipe_name,
    tag = "ContainerImage",
    config = recipe_config,
    inputs = {},
  },

  binary = fun recipe_name => fun recipe_config => fun image_input => fun script_input => fun source_inputs => {
    name = recipe_name,
    tag = "Binary",
    config = recipe_config,
    inputs = {
      image = image_input,
      script = script_input,
      sources = source_inputs,
    },
  },

  image = fun recipe_name => fun recipe_config => fun base_input => fun layer_inputs => {
    name = recipe_name,
    tag = "Image",
    config = { ref_name | default = recipe_name } & recipe_config,
    inputs = {
      base = base_input,
      inputs = layer_inputs,
    },
  },

  ext4_rootfs = fun recipe_name => fun recipe_config => fun tree_inputs => {
    name = recipe_name,
    tag = "Ext4Rootfs",
    config = recipe_config,
    inputs = {
      inputs = tree_inputs,
    },
  },
}
