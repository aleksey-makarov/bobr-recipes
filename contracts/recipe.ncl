let KnownTags = [
  "Fetch",
  "Text",
  "ContainerImage",
  "Binary",
  "Image",
]
in
let KnownTag =
  std.contract.from_predicate (fun value => std.array.elem value KnownTags)
in
let ArchiveFormat =
  std.contract.from_predicate (
    fun value => std.array.elem value [ "tar-gz", "tar-xz", "tar-bz2", "zip" ]
  )
in
let UrlField = std.contract.any_of [ String, Array String ] in
let BaseRecipe = {
  name
    | String
    | doc "Publication name of the recipe node.",
  tag
    | String
    | KnownTag
    | doc "Builder tag selected for this recipe node.",
  config
    | Dyn
    | doc "Builder-specific config payload.",
  inputs
    | { .. }
    | doc "Builder-specific input object.",
}
in
let TextConfig = {
  kind
    | String
    | doc "Requested output kind for the text builder.",
  source
    | String
    | doc "Literal text payload to stage into the output object.",
}
in
let FetchConfig = {
  url
    | UrlField
    | doc "Source URL or list of fallback URLs.",
  hash
    | String
    | doc "Declared source hash in `<algo>:<hex>` form.",
  unpack
    | Bool
    | optional
    | doc "Whether the fetched payload should be unpacked.",
  archive_format
    | ArchiveFormat
    | optional
    | doc "Optional explicit archive format override.",
  kind
    | String
    | optional
    | doc "Optional explicit output kind override for the fetch builder.",
}
in
let ContainerImageConfig = {
  image
    | String
    | doc "Pinned external image reference.",
  digest
    | String
    | doc "Pinned digest for the external image reference.",
}
in
let BinaryConfig = {
  kind
    | String
    | doc "Requested output kind for the binary builder.",
  script_config
    | Dyn
    | optional
    | doc "Optional script configuration payload passed through to the build script.",
}
in
let ImageConfig = {
  ref_name
    | String
    | optional
    | doc "Optional OCI ref-name annotation for the resulting image.",
  mode
    | String
    | optional
    | doc "Optional image build mode selector.",
}
in
let FetchInputs = {
}
in
let TextInputs = {
}
in
let ContainerImageInputs = {
}
in
let BinaryInputsShape = {
  image
    | Dyn
    | doc "Single recipe node for the container image input.",
  script
    | Dyn
    | doc "Single recipe node for the build script input.",
  sources
    | Array Dyn
    | doc "Repeated recipe nodes for source inputs.",
}
in
let ImageInputsShape = {
  base
    | Dyn
    | doc "Optional base image recipe node or null.",
  inputs
    | Array Dyn
    | doc "Repeated recipe nodes providing image layer inputs.",
}
in
let rec ValidateRecipe = fun recipe =>
  let checked = recipe | BaseRecipe in
  let validate_fetch_inputs = fun inputs =>
    inputs | FetchInputs
  in
  let validate_text_inputs = fun inputs =>
    inputs | TextInputs
  in
  let validate_container_image_inputs = fun inputs =>
    inputs | ContainerImageInputs
  in
  let validate_binary_inputs = fun inputs =>
    let checked = inputs | BinaryInputsShape in
    checked & {
      image = ValidateRecipe checked.image,
      script = ValidateRecipe checked.script,
      sources = std.array.map ValidateRecipe checked.sources,
    }
  in
  let validate_image_inputs = fun inputs =>
    let checked = inputs | ImageInputsShape in
    checked & {
      base =
        if checked.base == null then
          null
        else
          ValidateRecipe checked.base,
      inputs = std.array.map ValidateRecipe checked.inputs,
    }
  in
  if checked.tag == "Fetch" then
    checked & {
      config = checked.config | FetchConfig,
      inputs = validate_fetch_inputs checked.inputs,
    }
  else if checked.tag == "Text" then
    checked & {
      config = checked.config | TextConfig,
      inputs = validate_text_inputs checked.inputs,
    }
  else if checked.tag == "ContainerImage" then
    checked & {
      config = checked.config | ContainerImageConfig,
      inputs = validate_container_image_inputs checked.inputs,
    }
  else if checked.tag == "Binary" then
    checked & {
      config = checked.config | BinaryConfig,
      inputs = validate_binary_inputs checked.inputs,
    }
  else
    checked & {
      config = checked.config | ImageConfig,
      inputs = validate_image_inputs checked.inputs,
    }
in
{
  known_tags
    | Array String
    | doc "Closed set of currently supported recipe builder tags."
    = KnownTags,
  base_recipe
    | doc "Base structural contract shared by all recipe nodes."
    = BaseRecipe,
  text_config
    | doc "Config contract for `Text` recipe nodes."
    = TextConfig,
  fetch_config
    | doc "Config contract for `Fetch` recipe nodes."
    = FetchConfig,
  container_image_config
    | doc "Config contract for `ContainerImage` recipe nodes."
    = ContainerImageConfig,
  binary_config
    | doc "Config contract for `Binary` recipe nodes."
    = BinaryConfig,
  image_config
    | doc "Config contract for `Image` recipe nodes."
    = ImageConfig,
  validate_recipe
    | doc "Recursively validate one exported recipe graph value."
    = ValidateRecipe,
}
