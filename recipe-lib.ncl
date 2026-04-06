{
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
