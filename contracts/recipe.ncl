let KnownTags = [
  "Fetch",
  "Text",
  "Tree",
  "ContainerImage",
  "Binary",
  "Ext4Rootfs",
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
  source
    | String
    | doc "Literal text payload to stage into the output object.",
  executable
    | Bool
    | optional
    | doc "Whether the resulting staged file should be executable.",
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
}
in
let TreeFileEntry = {
  type
    | std.contract.Equal "file"
    | doc "Discriminator for one text file entry.",
  path
    | String
    | doc "Relative file path inside the staged object.",
  text
    | String
    | doc "Literal UTF-8 text payload for the staged file.",
  executable
    | Bool
    | doc "Whether the staged file should carry executable bits.",
}
in
let TreeDirEntry = {
  type
    | std.contract.Equal "dir"
    | doc "Discriminator for one explicit directory entry.",
  path
    | String
    | doc "Relative directory path inside the staged object.",
}
in
let TreeSymlinkEntry = {
  type
    | std.contract.Equal "symlink"
    | doc "Discriminator for one symlink entry.",
  path
    | String
    | doc "Relative symlink path inside the staged object.",
  target
    | String
    | doc "Literal symlink target stored in the staged object.",
}
in
let TreePayload = {
  entries
    | Array Dyn
    | doc "Generated tree entries describing text files, explicit directories, and symlinks.",
}
in
let TreeEntryKind =
  std.contract.from_predicate (fun value => std.array.elem value [ "file", "dir", "symlink" ])
in
let InstallMeta = {
  owners
    | Array {
        path | String,
        uid | Number,
        gid | Number,
      }
    | doc "Install ownership rules applied when the tree result is used as an installable directory object.",
}
in
let TreeConfig = {
  tree
    | TreePayload
    | doc "Generated tree description imported from a committed `*-tree.ncl` module.",
  install
    | InstallMeta
    | optional
    | doc "Manual install metadata for directory output only.",
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
let Ext4RootfsConfig = {
  size_mib
    | Number
    | doc "Explicit size of the resulting ext4 rootfs image in MiB.",
  label
    | String
    | optional
    | doc "Optional ext4 volume label.",
}
in
let FetchInputs = {
}
in
let TextInputs = {
}
in
let TreeInputs = {
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
let Ext4RootfsInputsShape = {
  inputs
    | Array Dyn
    | doc "Repeated recipe nodes providing installable filesystem tree inputs.",
}
in
let rec ValidateRecipe = fun recipe =>
  let checked = recipe | BaseRecipe in
  let validate_tree_entry = fun entry =>
    let checked = entry | { type | TreeEntryKind, .. } in
    if checked.type == "file" then
      checked | TreeFileEntry
    else if checked.type == "symlink" then
      checked | TreeSymlinkEntry
    else
      checked | TreeDirEntry
  in
  let validate_fetch_inputs = fun inputs =>
    inputs | FetchInputs
  in
  let validate_text_inputs = fun inputs =>
    inputs | TextInputs
  in
  let validate_tree_inputs = fun inputs =>
    inputs | TreeInputs
  in
  let validate_container_image_inputs = fun inputs =>
    inputs | ContainerImageInputs
  in
  let validate_tree_config = fun config =>
    let checked = config | TreeConfig in
    checked & {
      tree = checked.tree & {
        entries = std.array.map validate_tree_entry checked.tree.entries,
      },
    }
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
  let validate_ext4_rootfs_inputs = fun inputs =>
    let checked = inputs | Ext4RootfsInputsShape in
    checked & {
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
  else if checked.tag == "Tree" then
    checked & {
      config = validate_tree_config checked.config,
      inputs = validate_tree_inputs checked.inputs,
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
  else if checked.tag == "Ext4Rootfs" then
    checked & {
      config = checked.config | Ext4RootfsConfig,
      inputs = validate_ext4_rootfs_inputs checked.inputs,
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
  tree_config
    | doc "Config contract for `Tree` recipe nodes."
    = TreeConfig,
  fetch_config
    | doc "Config contract for `Fetch` recipe nodes."
    = FetchConfig,
  container_image_config
    | doc "Config contract for `ContainerImage` recipe nodes."
    = ContainerImageConfig,
  binary_config
    | doc "Config contract for `Binary` recipe nodes."
    = BinaryConfig,
  ext4_rootfs_config
    | doc "Config contract for `Ext4Rootfs` recipe nodes."
    = Ext4RootfsConfig,
  image_config
    | doc "Config contract for `Image` recipe nodes."
    = ImageConfig,
  validate_recipe
    | doc "Recursively validate one exported recipe graph value."
    = ValidateRecipe,
}
