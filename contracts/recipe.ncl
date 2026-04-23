let KnownTags = [
  "Source",
  "Fetch",
  "Text",
  "Tree",
  "ContainerImage",
  "Autotools",
  "Makefile",
  "Meson",
  "PerlModule",
  "Binary",
  "Ext4Rootfs",
  "Image",
]
in
let KnownTag =
  std.contract.from_predicate (fun value => std.array.elem value KnownTags)
in
let ArchiveFormat =
  std.contract.from_predicate (fun value => std.array.elem value ["tar-gz", "tar-xz", "tar-bz2", "zip"]
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
let ShallowBaseRecipe = {
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
    | Dyn
    | doc "Builder-specific input object left unvalidated in shallow mode.",
}
in
let SourcePathMode =
  std.contract.from_predicate (fun value => std.array.elem value ["direct", "tar"])
in
let SourceOrigin = {
  type | std.contract.Equal "path",
  path | String,
  mode | SourcePathMode,
}
in
let SourceRecipe = {
  name
    | String
    | doc "Publication name of the source recipe node.",
  tag
    | std.contract.Equal "Source"
    | doc "Special node tag for recipes with predeclared payload object identity.",
  object_hash
    | String
    | doc "Declared payload object hash materialized from `origin`; `result_id` is derived later from `object_hash` and `meta`.",
  origin | SourceOrigin,
  meta | { .. },
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
let InstallAttrs = {
  uid | Number | optional,
  gid | Number | optional,
  directory_mode | Number | optional,
  regular_file_mode | Number | optional,
  executable_file_mode | Number | optional,
  symlink_mode | Number | optional,
}
in
let InstallRule = {
  path | String,
  attrs
    | InstallAttrs
    | doc "Install attributes overridden for matching installed paths.",
}
in
let InstallMeta = {
  rules
    | Array InstallRule
    | doc "Install rules applied when the result is used as an installable object.",
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
  install
    | InstallMeta
    | optional
    | doc "Optional install metadata for unpacked directory output.",
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
  std.contract.from_predicate (fun value => std.array.elem value ["file", "dir", "symlink"])
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
  steps
    | Array {
      name | String,
      run_as | std.contract.from_predicate (fun value => std.array.elem value ["build-user", "root"]),
      cwd | String,
      argv | Array String,
      env | Dyn | optional,
    }
    | doc "Execution plan steps for the generic Binary executor.",
  script_config
    | Dyn
    | optional
    | doc "Optional script configuration payload passed through to the build script.",
  install
    | InstallMeta
    | optional
    | doc "Optional install metadata for the published directory output.",
}
in
let HookStep = {
  name | String,
  run_as | std.contract.from_predicate (fun value => std.array.elem value ["build-user", "root"]),
  cwd | String | optional,
  argv | Array String,
  env | Dyn | optional,
}
in
let AutotoolsHook =
  std.contract.any_of [
    HookStep,
    Array HookStep,
  ]
in
let AutotoolsConfig = {
  configure_args | Array String | optional,
  make_args | Array String | optional,
  env | Dyn | optional,
  "in-tree" | Bool | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
  install | InstallMeta | optional,
}
in
let MakefileConfig = {
  make_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_build | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
  skip_install | Bool | optional,
  install | InstallMeta | optional,
}
in
let MesonConfig = {
  setup_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  build_dir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
  install | InstallMeta | optional,
}
in
let PerlModuleConfig = {
  perl_args | Array String | optional,
  make_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
  install | InstallMeta | optional,
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
let FetchInputs = {}
in
let TextInputs = {}
in
let TreeInputs = {}
in
let ContainerImageInputs = {}
in
let BinaryInputsShape = {
  image
    | Dyn
    | doc "Single recipe node for the container image input.",
  ..
}
in
let ImageInputsShape = {
  base
    | Dyn
    | optional
    | doc "Optional base image recipe node.",
  ..
}
in
let Ext4RootfsInputsShape = { .. }
in
let AutotoolsInputsShape = {
  image | Dyn,
  source | Dyn,
  ..
}
in
let MakefileInputsShape = {
  image | Dyn,
  source | Dyn,
  ..
}
in
let MesonInputsShape = {
  image | Dyn,
  source | Dyn,
  ..
}
in
let PerlModuleInputsShape = {
  image | Dyn,
  source | Dyn,
  ..
}
in
let ValidateRecipeShallow = fun recipe =>
  if recipe.tag == "Source" then
    recipe | SourceRecipe
  else
    let checked = recipe | ShallowBaseRecipe in
    let validate_tree_entry = fun entry =>
      let checked = entry | { type | TreeEntryKind, .. } in
      if checked.type == "file" then
        checked | TreeFileEntry
      else if checked.type == "symlink" then
        checked | TreeSymlinkEntry
      else
        checked | TreeDirEntry
    in
    let validate_tree_config = fun config =>
      let checked = config | TreeConfig in
      checked
      & {
        tree =
          checked.tree
          & {
            entries = std.array.map validate_tree_entry checked.tree.entries,
          },
      }
    in
    if checked.tag == "Fetch" then
      let config = checked.config | FetchConfig in
      checked
      & {
        config =
          if std.record.has_field "install" config then
            config & { install = config.install | InstallMeta }
          else
            config,
      }
    else if checked.tag == "Text" then
      checked
      & {
        config = checked.config | TextConfig,
      }
    else if checked.tag == "Tree" then
      checked
      & {
        config = validate_tree_config checked.config,
      }
    else if checked.tag == "ContainerImage" then
      checked
      & {
        config = checked.config | ContainerImageConfig,
      }
    else if checked.tag == "Autotools" then
      checked
      & {
        config = checked.config | AutotoolsConfig,
      }
    else if checked.tag == "Makefile" then
      checked
      & {
        config = checked.config | MakefileConfig,
      }
    else if checked.tag == "Meson" then
      checked
      & {
        config = checked.config | MesonConfig,
      }
    else if checked.tag == "PerlModule" then
      checked
      & {
        config = checked.config | PerlModuleConfig,
      }
    else if checked.tag == "Binary" then
      checked
      & {
        config = checked.config | BinaryConfig,
      }
    else if checked.tag == "Ext4Rootfs" then
      checked
      & {
        config = checked.config | Ext4RootfsConfig,
      }
    else
      checked
      & {
        config = checked.config | ImageConfig,
      }
in
# WARNING:
# `ValidateRecipe` performs a deep recursive traversal of the entire nested
# raw recipe graph. It is intentionally expensive and should only be used for
# small smoke cases, not for full-package-set validation.
let rec ValidateRecipe = fun recipe =>
  if recipe.tag == "Source" then
    recipe | SourceRecipe
  else
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
    let validate_autotools_inputs = fun inputs =>
      let checked = inputs | AutotoolsInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_makefile_inputs = fun inputs =>
      let checked = inputs | MakefileInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_meson_inputs = fun inputs =>
      let checked = inputs | MesonInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_perl_module_inputs = fun inputs =>
      let checked = inputs | PerlModuleInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_tree_config = fun config =>
      let checked = config | TreeConfig in
      checked
      & {
        tree =
          checked.tree
          & {
            entries = std.array.map validate_tree_entry checked.tree.entries,
          },
      }
    in
    let validate_binary_inputs = fun inputs =>
      let checked = inputs | BinaryInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_image_inputs = fun inputs =>
      let checked = inputs | ImageInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_ext4_rootfs_inputs = fun inputs =>
      let checked = inputs | Ext4RootfsInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    if checked.tag == "Fetch" then
      checked
      & {
        config = checked.config | FetchConfig,
        inputs = validate_fetch_inputs checked.inputs,
      }
    else if checked.tag == "Text" then
      checked
      & {
        config = checked.config | TextConfig,
        inputs = validate_text_inputs checked.inputs,
      }
    else if checked.tag == "Tree" then
      checked
      & {
        config = validate_tree_config checked.config,
        inputs = validate_tree_inputs checked.inputs,
      }
    else if checked.tag == "ContainerImage" then
      checked
      & {
        config = checked.config | ContainerImageConfig,
        inputs = validate_container_image_inputs checked.inputs,
      }
    else if checked.tag == "Autotools" then
      checked
      & {
        config = checked.config | AutotoolsConfig,
        inputs = validate_autotools_inputs checked.inputs,
      }
    else if checked.tag == "Makefile" then
      checked
      & {
        config = checked.config | MakefileConfig,
        inputs = validate_makefile_inputs checked.inputs,
      }
    else if checked.tag == "Meson" then
      checked
      & {
        config = checked.config | MesonConfig,
        inputs = validate_meson_inputs checked.inputs,
      }
    else if checked.tag == "PerlModule" then
      checked
      & {
        config = checked.config | PerlModuleConfig,
        inputs = validate_perl_module_inputs checked.inputs,
      }
    else if checked.tag == "Binary" then
      checked
      & {
        config = checked.config | BinaryConfig,
        inputs = validate_binary_inputs checked.inputs,
      }
    else if checked.tag == "Ext4Rootfs" then
      checked
      & {
        config = checked.config | Ext4RootfsConfig,
        inputs = validate_ext4_rootfs_inputs checked.inputs,
      }
    else
      checked
      & {
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
  source_recipe
    | doc "Structural contract for `Source` recipe nodes."
    = SourceRecipe,
  container_image_config
    | doc "Config contract for `ContainerImage` recipe nodes."
    = ContainerImageConfig,
  autotools_config
    | doc "Config contract for synthetic `Autotools` recipe nodes."
    = AutotoolsConfig,
  makefile_config
    | doc "Config contract for synthetic `Makefile` recipe nodes."
    = MakefileConfig,
  meson_config
    | doc "Config contract for synthetic `Meson` recipe nodes."
    = MesonConfig,
  perl_module_config
    | doc "Config contract for synthetic `PerlModule` recipe nodes."
    = PerlModuleConfig,
  binary_config
    | doc "Config contract for `Binary` recipe nodes."
    = BinaryConfig,
  ext4_rootfs_config
    | doc "Config contract for `Ext4Rootfs` recipe nodes."
    = Ext4RootfsConfig,
  image_config
    | doc "Config contract for `Image` recipe nodes."
    = ImageConfig,
  shallow_recipe
    | doc "Validate one recipe node shallowly: full top-level shape and tag-specific config, but leave `inputs` as `Dyn`."
    =
      std.contract.from_predicate (fun recipe =>
        let _ = ValidateRecipeShallow recipe in
        true
      ),
  validate_recipe
    | doc "WARNING: deep recursive validation. This walks the entire nested recipe graph and is expensive on large raw package sets."
    = ValidateRecipe,
}
