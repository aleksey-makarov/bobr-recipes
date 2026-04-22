let default_binary_sequence = [
  {
    name = "configure",
    run_as = "build-user",
    cwd = "${build_dir}",
    argv = ["${script}", "configure"],
  },
  {
    name = "build",
    run_as = "build-user",
    cwd = "${build_dir}",
    argv = ["${script}", "build"],
  },
  {
    name = "install",
    run_as = "root",
    cwd = "${build_dir}",
    argv = ["${script}", "install"],
  },
  {
    name = "post_install",
    run_as = "root",
    cwd = "${build_dir}",
    argv = ["${script}", "post_install"],
  },
]
in
let synthetic_registry = import "synthetic/registry.ncl" in
let lower_node = fun node =>
  if std.record.has_field node.tag synthetic_registry then
    (std.record.get node.tag synthetic_registry) node
  else
    node
in
let append_steps_fn = fun new_steps =>
  fun steps => steps @ new_steps
in
let prepend_steps_fn = fun new_steps =>
  fun steps => new_steps @ steps
in
let insert_before_step_fn = fun target_name =>
  fun new_steps =>
    fun steps =>
      std.array.fold_right
        (fun step =>
          fun acc =>
            if step.name == target_name then
              new_steps @ [step] @ acc
            else
              [step] @ acc
        )
        []
        steps
in
let insert_after_step_fn = fun target_name =>
  fun new_steps =>
    fun steps =>
      std.array.fold_right
        (fun step =>
          fun acc =>
            if step.name == target_name then
              [step] @ new_steps @ acc
            else
              [step] @ acc
        )
        []
        steps
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

  steps = {
    step = fun step_name =>
      fun step_run_as =>
        fun step_cwd =>
          fun step_argv =>
            {
              name = step_name,
              run_as = step_run_as,
              cwd = step_cwd,
              argv = step_argv,
            },

    env_step = fun step_name =>
      fun step_run_as =>
        fun step_cwd =>
          fun step_argv =>
            fun step_env =>
              {
                name = step_name,
                run_as = step_run_as,
                cwd = step_cwd,
                argv = step_argv,
                env = step_env,
              },

    append = append_steps_fn,
    prepend = prepend_steps_fn,
    insert_before_step = insert_before_step_fn,
    insert_after_step = insert_after_step_fn,

    default_binary_sequence = default_binary_sequence,
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
          std.array.fold_left
            (fun acc =>
              fun slot_name =>
                let input = std.record.get slot_name lowered_node.inputs in
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
            (std.record.fields lowered_node.inputs)
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
    let input_to_id = fun input =>
      if input == null then
        null
      else if std.is_array input then
        std.array.map
          (fun child => std.record.get child.name name_to_id)
          input
      else
        std.record.get input.name name_to_id
    in
    std.record.from_array (
      std.array.map
        (fun name =>
          let node = lower_node (std.record.get name unique_nodes) in
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
}
