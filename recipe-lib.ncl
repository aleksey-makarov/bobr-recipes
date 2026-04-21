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
let buildscript_autotools = {
  name = "buildscript-autotools",
  tag = "Text",
  config = {
    executable = true,
    source = import "buildscripts/autotools.sh" as 'Text,
  },
  inputs = {},
}
in
let record_get_or = fun field =>
  fun fallback =>
    fun record =>
      if std.record.has_field field record then
        std.record.get field record
      else
        fallback
in
let autotools_source_root_expr = fun node_config =>
  if std.record.has_field "source_subdir" node_config then
    "${source}/" ++ node_config.source_subdir
  else
    "${source}"
in
let lower_autotools_node = fun node =>
  let node_config = node.config in
  let source_root_expr = autotools_source_root_expr node_config in
  let normalize_steps = fun field_name =>
    fun default_cwd =>
      if std.record.has_field field_name node_config then
        let normalize_step = fun step =>
          if std.record.has_field "cwd" step then
            step
          else
            std.record.insert "cwd" default_cwd step
        in
        if std.is_array (std.record.get field_name node_config) then
          std.array.map normalize_step (std.record.get field_name node_config)
        else
          [normalize_step (std.record.get field_name node_config)]
      else
        []
  in
  let pre_configure_steps =
    normalize_steps "pre_configure" source_root_expr
  in
  let post_install_steps =
    normalize_steps "post_install" "${out}"
  in
  let lowered_script_config =
    let with_configure_args =
      if std.record.has_field "configure_args" node_config then
        { configure_args = node_config.configure_args }
      else
        {}
    in
    let with_make_args =
      if std.record.has_field "make_args" node_config then
        std.record.insert "make_args" node_config.make_args with_configure_args
      else
        with_configure_args
    in
    let with_env =
      if std.record.has_field "env" node_config then
        std.record.insert "env" node_config.env with_make_args
      else
        with_make_args
    in
    let with_source_subdir =
      if std.record.has_field "source_subdir" node_config then
        std.record.insert "source_subdir" node_config.source_subdir with_env
      else
        with_env
    in
    if record_get_or "in-tree" false node_config then
      std.record.insert "in-tree" "true" with_source_subdir
    else
      with_source_subdir
  in
  let autotools_step_env = {
    MBUILD_SOURCE_DIR = "${source}",
    MBUILD_IN1 = "${source}",
  }
  in
  {
    name = node.name,
    tag = "Binary",
    config = (
      {
        steps =
          pre_configure_steps
          @ [
            {
              name = "configure",
              run_as = "build-user",
              cwd = "${build}",
              argv = ["${script}", "configure"],
              env = autotools_step_env,
            },
            {
              name = "build",
              run_as = "build-user",
              cwd = "${build}",
              argv = ["${script}", "build"],
              env = autotools_step_env,
            },
            {
              name = "install",
              run_as = "root",
              cwd = "${build}",
              argv = ["${script}", "install"],
              env = autotools_step_env,
            },
          ]
          @ post_install_steps,
        script_config = lowered_script_config,
      }
      & (
        if std.record.has_field "install" node_config then
          { install = node_config.install }
        else
          {}
      )
    ),
    inputs =
      std.record.insert
        "script"
        buildscript_autotools
        node.inputs,
  }
in
let lower_node = fun node =>
  if node.tag == "Autotools" then
    lower_autotools_node node
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

  binary = fun recipe_name =>
    fun recipe_config =>
      fun image_input =>
        fun input_nodes =>
          {
            name = recipe_name,
            tag = "Binary",
            config = recipe_config,
            inputs = {
              image = image_input,
              "in" = input_nodes,
            },
          },
}
