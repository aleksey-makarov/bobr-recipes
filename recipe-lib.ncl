let synthetic_registry = import "synthetic/registry.ncl" in
let lower_node = fun node =>
  if std.record.has_field node.tag synthetic_registry then
    (std.record.get node.tag synthetic_registry) node
  else
    node
in
let node_inputs = fun node =>
  if node.tag == "Source" then
    {}
  else
    node.inputs
in
let pad3 = fun n =>
  let digits = std.string.from_number n in
  if n < 10 then
    "00" ++ digits
  else if n < 100 then
    "0" ++ digits
  else
    digits
in
let numbered_inputs_fn = fun inputs =>
  std.record.from_array (
    std.array.map_with_index
      (fun idx =>
        fun input =>
          {
            field = "n" ++ pad3 idx,
            value = input,
          }
      )
      inputs
  )
in
let old_style_input_error = fun node_name =>
  fun slot_name =>
    fun shape =>
      std.record.get
        (
          "recipe-lib.to_request: input '" ++ slot_name
          ++ "' of node '" ++ node_name
          ++ "' uses unsupported old-style " ++ shape
        )
        {}
in
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

  numbered_inputs = numbered_inputs_fn,

  to_request = fun root_node =>
    let lowered_root_node = lower_node root_node in
    let rec collect = fun seen =>
      fun node =>
        let lowered_node = lower_node node in
        if std.record.has_field lowered_node.name seen then
          seen
        else
          let seen_with_node = std.record.insert lowered_node.name lowered_node seen in
          let inputs = node_inputs lowered_node in
          std.array.fold_left
            (fun acc =>
              fun slot_name =>
                let input = std.record.get slot_name inputs in
                let validated_input =
                  if input == null then
                    old_style_input_error lowered_node.name slot_name "null"
                  else if std.is_array input then
                    old_style_input_error lowered_node.name slot_name "array"
                  else
                    input
                in
                collect acc validated_input
            )
            seen_with_node
            (std.record.fields inputs)
    in

    let unique_nodes = collect {} lowered_root_node in
    let root_name = lowered_root_node.name in
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
      std.record.from_array (
        [{ field = root_name, value = "root" }]
        @ std.array.map_with_index
          (fun idx =>
            fun name =>
              {
                field = name,
                value = "n" ++ std.string.from_number idx,
              }
          )
          other_names
      )
    in
    let input_to_id = fun node_name =>
      fun slot_name =>
        fun input =>
          if input == null then
            old_style_input_error node_name slot_name "null"
          else if std.is_array input then
            old_style_input_error node_name slot_name "array"
          else
        std.record.get input.name name_to_id
    in
    std.record.from_array (
      std.array.map
        (fun name =>
          let node = lower_node (std.record.get name unique_nodes) in
          let node_value =
            if node.tag == "Source" then
              {
                name = node.name,
                tag = node.tag,
                object_hash = node.object_hash,
                origin = node.origin,
                meta = node.meta,
              }
            else
              {
                name = node.name,
                tag = node.tag,
                config = node.config,
                inputs =
                  std.record.map
                    (fun slot_name input => input_to_id node.name slot_name input)
                    node.inputs,
              }
          in
          {
            field = std.record.get name name_to_id,
            value = node_value,
          }
        )
        ordered_names
    ),
}
