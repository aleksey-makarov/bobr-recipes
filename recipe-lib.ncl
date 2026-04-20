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
] in
let autotools_default_steps = [
  {
    name = "configure",
    run_as = "build-user",
    cwd = "${build}",
    argv = ["${in0}", "configure"],
  },
  {
    name = "build",
    run_as = "build-user",
    cwd = "${build}",
    argv = ["${in0}", "build"],
  },
  {
    name = "install",
    run_as = "root",
    cwd = "${build}",
    argv = ["${in0}", "install"],
  },
] in
let buildscript_autotools = {
  name = "buildscript-autotools",
  tag = "Text",
  config = {
    executable = true,
    source = import "buildscripts/autotools.sh" as 'Text,
  },
  inputs = {},
} in
let identity = fun x => x in
let append_steps_fn =
  fun new_steps =>
  fun steps => steps @ new_steps
in
let prepend_steps_fn =
  fun new_steps =>
  fun steps => new_steps @ steps
in
let insert_before_step_fn =
  fun target_name =>
  fun new_steps =>
  fun steps =>
    std.array.fold_right
      (
        fun step =>
        fun acc =>
          if step.name == target_name then
            new_steps @ [step] @ acc
          else
            [step] @ acc
      )
      []
      steps
in
let insert_after_step_fn =
  fun target_name =>
  fun new_steps =>
  fun steps =>
    std.array.fold_right
      (
        fun step =>
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
    step =
      fun step_name =>
      fun step_run_as =>
      fun step_cwd =>
      fun step_argv => {
        name = step_name,
        run_as = step_run_as,
        cwd = step_cwd,
        argv = step_argv,
      },

    env_step =
      fun step_name =>
      fun step_run_as =>
      fun step_cwd =>
      fun step_argv =>
      fun step_env => {
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

  container_image = fun recipe_name => fun recipe_config => {
    name = recipe_name,
    tag = "ContainerImage",
    config = recipe_config,
    inputs = {},
  },

  binary = fun recipe_name => fun recipe_config => fun image_input => fun input_nodes => {
    name = recipe_name,
    tag = "Binary",
    config = recipe_config,
    inputs = {
      image = image_input,
      "in" = input_nodes,
    },
  },

  autotools = {
    binary =
      fun recipe_name =>
      fun recipe_config =>
      fun image_input =>
      fun source_inputs =>
        let step_transform =
          if std.record.has_field "step_transform" recipe_config then
            std.record.get "step_transform" recipe_config
          else
            identity
        in
        let script_config =
          if std.record.has_field "script_config" recipe_config then
            std.record.get "script_config" recipe_config
          else
            {}
        in
        let in_tree =
          if std.record.has_field "in-tree" recipe_config then
            std.record.get "in-tree" recipe_config
          else
            false
        in
        let final_script_config =
          if in_tree then
            std.record.insert "in-tree" "true" script_config
          else
            script_config
        in
        {
          name = recipe_name,
          tag = "Binary",
          config = ({
            steps = step_transform autotools_default_steps,
            script_config = final_script_config,
          } &
          (
            if std.record.has_field "install" recipe_config then
              { install = recipe_config.install }
            else
              {}
          )),
          inputs = {
            image = image_input,
            "in" = [buildscript_autotools] @ source_inputs,
          },
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
