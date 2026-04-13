{
  to_request =
    fun root_node =>
      let initial_state = {
        next_id = 0,
        name_to_id = {},
        nodes = {},
      } in

      let rec visit =
        fun st =>
        fun is_root =>
        fun node =>
          let visit_input =
            fun st =>
            fun input =>
              if input == null then
                { state = st, value = null }
              else if std.is_array input then
                let folded =
                  std.array.fold_left
                    (
                      fun acc =>
                      fun item =>
                        let visited = visit acc.state false item in
                        {
                          state = visited.state,
                          values = acc.values @ [visited.id],
                        }
                    )
                    {
                      state = st,
                      values = [],
                    }
                    input
                in
                { state = folded.state, value = folded.values }
              else
                let visited = visit st false input in
                { state = visited.state, value = visited.id }
          in

          if (!is_root) && std.record.has_field node.name st.name_to_id then
            {
              state = st,
              id = std.record.get node.name st.name_to_id,
            }
          else
            let node_id =
              if is_root then
                "root"
              else
                "n" ++ std.string.from_number st.next_id
            in

            let state_with_id = {
              next_id =
                if is_root then
                  st.next_id
                else
                  st.next_id + 1,
              name_to_id = std.record.insert node.name node_id st.name_to_id,
              nodes = st.nodes,
            } in

            let inputs_result =
              std.array.fold_left
                (
                  fun acc =>
                  fun slot_name =>
                    let converted = visit_input acc.state (std.record.get slot_name node.inputs) in
                    {
                      state = converted.state,
                      inputs = std.record.insert slot_name converted.value acc.inputs,
                    }
                )
                {
                  state = state_with_id,
                  inputs = {},
                }
                (std.record.fields node.inputs)
            in

            let request_node = {
              name = node.name,
              tag = node.tag,
              config = node.config,
              inputs = inputs_result.inputs,
            } in

            let final_state = inputs_result.state & {
              nodes = std.record.insert node_id request_node inputs_result.state.nodes,
            } in

            {
              state = final_state,
              id = node_id,
            }
      in

      let root = visit initial_state true root_node in
      root.state.nodes,

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
