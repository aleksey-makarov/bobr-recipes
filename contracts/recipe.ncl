let KnownTags = [
  "Source",
  "Text",
  "Tree",
  "TreeMerge",
  "ErofsRootfs",
  "AutotoolsSandbox",
  "MakefileSandbox",
  "MesonSandbox",
  "PerlModuleSandbox",
  "Sandbox",
  "Image",
  "OciExtract",
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
let RelativeSourcePath =
  std.contract.from_predicate (fun value =>
    std.is_string value
    && value != ""
    && !std.string.is_match "^/" value
    && !std.string.is_match "(^|/)\\.\\.($|/)" value
  )
in
let SourcePathOrigin = {
  type | std.contract.Equal "path",
  path
    | RelativeSourcePath
    | doc "Relative local source path without `..`, resolved from request `paths.local`.",
  mode | SourcePathMode,
}
in
let SourceHttpOrigin = {
  type | std.contract.Equal "http",
  url
    | UrlField
    | doc "HTTP(S) source URL or list of fallback URLs.",
  unpack
    | Bool
    | optional
    | doc "Whether the downloaded payload should be unpacked into a directory object; defaults to false.",
  archive_format
    | ArchiveFormat
    | optional
    | doc "Optional explicit archive format override.",
}
in
let SourceOciRegistryOrigin = {
  type | std.contract.Equal "oci-registry",
  image
    | String
    | doc "Pinned external image reference resolved through the OCI/Docker registry API.",
  digest
    | String
    | doc "Pinned manifest or index digest to request from the registry.",
}
in
let SourceOrigin =
  std.contract.any_of [
    SourcePathOrigin,
    SourceHttpOrigin,
    SourceOciRegistryOrigin,
  ]
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
  origin
    | SourceOrigin
    | optional
    | doc "Optional source origin. If omitted, the canonical result must already exist in store.",
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
let SourceMeta = {
  install | InstallMeta | optional,
  ..
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
let SandboxConfig = {
  steps
    | Array {
      name | String,
      run_as | std.contract.from_predicate (fun value => std.array.elem value ["build-user", "root"]),
      cwd | String,
      argv | Array String,
      env | Dyn | optional,
    }
    | doc "Execution plan steps for the generic Sandbox executor.",
  script_config
    | Dyn
    | optional
    | doc "Optional script configuration payload passed through to the build script.",
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
let AutotoolsSandboxConfig = {
  configure_args | Array String | optional,
  make_args | Array String | optional,
  env | Dyn | optional,
  "in-tree" | Bool | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
}
in
let MakefileSandboxConfig = {
  make_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_build | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
  skip_install | Bool | optional,
}
in
let MesonSandboxConfig = {
  setup_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  build_dir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
}
in
let PerlModuleSandboxConfig = {
  perl_args | Array String | optional,
  make_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
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
let TreeMergeConfig =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let ErofsNullableString =
  std.contract.from_predicate (fun value => value == null || std.is_string value && value != "")
in
let ErofsRootfsConfig = {
  compression
    | ErofsNullableString
    | optional
    | doc "Optional EROFS compression setting. `null` means plain EROFS.",
  label
    | ErofsNullableString
    | optional
    | doc "Optional EROFS filesystem label. `null` means no label.",
}
in
let OciExtractConfig =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let TextInputs = {}
in
let TreeInputs = {}
in
let SandboxInputsShape = {
  rootfs
    | Dyn
    | doc "Single recipe node for the rootfs directory input.",
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
let OciExtractInputsShape = {
  image
    | Dyn
    | doc "Single OCI image layout input to extract into a filesystem tree.",
}
in
let TreeMergeInputsShape = { .. }
in
let ErofsRootfsInputsShape = { .. }
in
let MakefileSandboxInputsShape = {
  rootfs | Dyn,
  source | Dyn,
  ..
}
in
let MesonSandboxInputsShape = {
  rootfs | Dyn,
  source | Dyn,
  ..
}
in
let PerlModuleSandboxInputsShape = {
  rootfs | Dyn,
  source | Dyn,
  ..
}
in
let ValidateRecipeShallow = fun recipe =>
  if recipe.tag == "Source" then
    let checked = recipe | SourceRecipe in
    checked & { meta = checked.meta | SourceMeta }
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
    if checked.tag == "Text" then
      checked
      & {
        config = checked.config | TextConfig,
      }
    else if checked.tag == "Tree" then
      checked
      & {
        config = validate_tree_config checked.config,
      }
    else if checked.tag == "AutotoolsSandbox" then
      checked
      & {
        config = checked.config | AutotoolsSandboxConfig,
      }
    else if checked.tag == "MakefileSandbox" then
      checked
      & {
        config = checked.config | MakefileSandboxConfig,
      }
    else if checked.tag == "MesonSandbox" then
      checked
      & {
        config = checked.config | MesonSandboxConfig,
      }
    else if checked.tag == "PerlModuleSandbox" then
      checked
      & {
        config = checked.config | PerlModuleSandboxConfig,
      }
    else if checked.tag == "Sandbox" then
      checked
      & {
        config = checked.config | SandboxConfig,
      }
    else if checked.tag == "TreeMerge" then
      checked
      & {
        config = checked.config | TreeMergeConfig,
      }
    else if checked.tag == "ErofsRootfs" then
      checked
      & {
        config = checked.config | ErofsRootfsConfig,
      }
    else if checked.tag == "OciExtract" then
      checked
      & {
        config = checked.config | OciExtractConfig,
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
    let checked = recipe | SourceRecipe in
    checked & { meta = checked.meta | SourceMeta }
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
    let validate_text_inputs = fun inputs =>
      inputs | TextInputs
    in
    let validate_tree_inputs = fun inputs =>
      inputs | TreeInputs
    in
    let validate_autotools_sandbox_inputs = fun inputs =>
      let checked = inputs | MakefileSandboxInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_makefile_sandbox_inputs = fun inputs =>
      let checked = inputs | MakefileSandboxInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_meson_sandbox_inputs = fun inputs =>
      let checked = inputs | MesonSandboxInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_perl_module_sandbox_inputs = fun inputs =>
      let checked = inputs | PerlModuleSandboxInputsShape in
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
    let validate_sandbox_inputs = fun inputs =>
      let checked = inputs | SandboxInputsShape in
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
    let validate_oci_extract_inputs = fun inputs =>
      let checked = inputs | OciExtractInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_tree_merge_inputs = fun inputs =>
      let checked = inputs | TreeMergeInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_erofs_rootfs_inputs = fun inputs =>
      let checked = inputs | ErofsRootfsInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    if checked.tag == "Text" then
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
    else if checked.tag == "AutotoolsSandbox" then
      checked
      & {
        config = checked.config | AutotoolsSandboxConfig,
        inputs = validate_autotools_sandbox_inputs checked.inputs,
      }
    else if checked.tag == "MakefileSandbox" then
      checked
      & {
        config = checked.config | MakefileSandboxConfig,
        inputs = validate_makefile_sandbox_inputs checked.inputs,
      }
    else if checked.tag == "MesonSandbox" then
      checked
      & {
        config = checked.config | MesonSandboxConfig,
        inputs = validate_meson_sandbox_inputs checked.inputs,
      }
    else if checked.tag == "PerlModuleSandbox" then
      checked
      & {
        config = checked.config | PerlModuleSandboxConfig,
        inputs = validate_perl_module_sandbox_inputs checked.inputs,
      }
    else if checked.tag == "Sandbox" then
      checked
      & {
        config = checked.config | SandboxConfig,
        inputs = validate_sandbox_inputs checked.inputs,
      }
    else if checked.tag == "TreeMerge" then
      checked
      & {
        config = checked.config | TreeMergeConfig,
        inputs = validate_tree_merge_inputs checked.inputs,
      }
    else if checked.tag == "ErofsRootfs" then
      checked
      & {
        config = checked.config | ErofsRootfsConfig,
        inputs = validate_erofs_rootfs_inputs checked.inputs,
      }
    else if checked.tag == "OciExtract" then
      checked
      & {
        config = checked.config | OciExtractConfig,
        inputs = validate_oci_extract_inputs checked.inputs,
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
  source_recipe
    | doc "Structural contract for `Source` recipe nodes."
    = SourceRecipe,
  autotools_sandbox_config
    | doc "Config contract for synthetic `AutotoolsSandbox` recipe nodes."
    = AutotoolsSandboxConfig,
  makefile_sandbox_config
    | doc "Config contract for synthetic `MakefileSandbox` recipe nodes."
    = MakefileSandboxConfig,
  meson_sandbox_config
    | doc "Config contract for synthetic `MesonSandbox` recipe nodes."
    = MesonSandboxConfig,
  perl_module_sandbox_config
    | doc "Config contract for synthetic `PerlModuleSandbox` recipe nodes."
    = PerlModuleSandboxConfig,
  sandbox_config
    | doc "Config contract for `Sandbox` recipe nodes."
    = SandboxConfig,
  tree_merge_config
    | doc "Config contract for `TreeMerge` recipe nodes."
    = TreeMergeConfig,
  erofs_rootfs_config
    | doc "Config contract for `ErofsRootfs` recipe nodes."
    = ErofsRootfsConfig,
  image_config
    | doc "Config contract for `Image` recipe nodes."
    = ImageConfig,
  oci_extract_config
    | doc "Config contract for `OciExtract` recipe nodes."
    = OciExtractConfig,
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
