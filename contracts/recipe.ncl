let KnownTags = [
  "Source",
  "Group",
  "Tree",
  "FsTreeImport",
  "TreeMerge",
  "TreeSubset",
  "RootfsClosure",
  "ErofsRootfs",
  "Initramfs",
  "Autotools",
  "Makefile",
  "Meson",
  "PerlModule",
  "SandboxBuild",
  "AutotoolsRootfs",
  "MakefileRootfs",
  "MesonRootfs",
  "PerlModuleRootfs",
  "SandboxBuildRootfs",
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
let RecipeDeps = {
  build | Array Dyn,
  runtime | Array Dyn,
}
in
let UrlField = std.contract.any_of [ String, Array String ] in
# Raw Nickel recipe records are open on purpose: package modules may carry
# local parameters such as `version`. `recipe.to_request` is the boundary that
# serializes only runtime-facing recipe fields.
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
  deps
    | RecipeDeps
    | optional
    | doc "Optional Nickel-level direct build/runtime dependencies for dependency-aware synthetic recipes.",
  ..
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
  deps
    | RecipeDeps
    | optional
    | doc "Optional Nickel-level direct build/runtime dependencies for dependency-aware synthetic recipes.",
  ..
}
in
let is_relative_source_path = fun value =>
    std.is_string value
    && value != ""
    && !std.string.is_match "^/" value
    && !std.string.is_match "(^|/)\\.\\.($|/)" value
in
let RelativeSourcePath =
  std.contract.from_predicate is_relative_source_path
in
let is_absolute_source_path = fun value =>
    std.is_string value
    && std.string.is_match "^/" value
in
let AbsoluteSourcePath =
  std.contract.from_predicate is_absolute_source_path
in
let SourcePathOrigin = {
  tag | std.contract.Equal "Path",
  path
    | AbsoluteSourcePath
    | doc "Absolute host source path.",
  unpack
    | Bool
    | optional
    | doc "Whether the local source archive should be unpacked into a directory object; defaults to false.",
}
in
let SourceRecipePathOrigin = {
  tag | std.contract.Equal "RecipePath",
  path
    | RelativeSourcePath
    | doc "Relative source path inside the bobr-recipes checkout, lowered to `Path` during request export.",
  unpack
    | Bool
    | optional
    | doc "Whether the local source archive should be unpacked into a directory object; defaults to false.",
}
in
let SourceHttpOrigin = {
  tag | std.contract.Equal "Http",
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
let SourceOciPlatform = {
  os
    | String
    | doc "OCI platform operating system, for example `linux`.",
  architecture
    | String
    | doc "OCI platform architecture, for example `amd64`.",
}
in
let SourceOciRegistryOrigin = {
  tag | std.contract.Equal "OciRegistry",
  image
    | String
    | doc "Pinned external image reference resolved through the OCI/Docker registry API.",
  digest
    | String
    | doc "Pinned manifest or index digest to request from the registry.",
  platform
    | SourceOciPlatform
    | doc "OCI platform selected when the pinned digest is an image index or manifest list.",
}
in
let has_field = fun field => fun record => std.record.has_field field record in
let get_field = fun field => fun record => std.record.get field record in
let all_fields_allowed = fun allowed =>
  fun record =>
    std.array.fold_left
      (fun acc => fun field => acc && std.array.elem field allowed)
      true
      (std.record.fields record)
in
let optional_bool_field = fun field =>
  fun record =>
    !has_field field record || std.is_bool (get_field field record)
in
let optional_archive_format_field = fun field =>
  fun record =>
    !has_field field record || std.array.elem (get_field field record) ["tar-gz", "tar-xz", "tar-bz2", "zip"]
in
let array_all_strings = fun value =>
  std.array.fold_left
    (fun acc => fun item => acc && std.is_string item)
    true
    value
in
let valid_url_field = fun value =>
  std.is_string value
  || (std.is_array value && std.array.length value > 0 && array_all_strings value)
in
let valid_oci_platform = fun value =>
  std.is_record value
  && all_fields_allowed ["os", "architecture"] value
  && has_field "os" value
  && std.is_string value.os
  && value.os != ""
  && has_field "architecture" value
  && std.is_string value.architecture
  && value.architecture != ""
in
let SourceOrigin =
  std.contract.from_predicate (fun value =>
    std.is_record value
    && has_field "tag" value
    && std.is_string value.tag
    && (
      if value.tag == "Path" then
        all_fields_allowed ["tag", "path", "unpack"] value
        && has_field "path" value
        && is_absolute_source_path value.path
        && optional_bool_field "unpack" value
      else if value.tag == "RecipePath" then
        all_fields_allowed ["tag", "path", "unpack"] value
        && has_field "path" value
        && is_relative_source_path value.path
        && optional_bool_field "unpack" value
      else if value.tag == "Http" then
        all_fields_allowed ["tag", "url", "unpack", "archive_format"] value
        && has_field "url" value
        && valid_url_field value.url
        && optional_bool_field "unpack" value
        && optional_archive_format_field "archive_format" value
      else if value.tag == "OciRegistry" then
        all_fields_allowed ["tag", "image", "digest", "platform"] value
        && has_field "image" value
        && std.is_string value.image
        && has_field "digest" value
        && std.is_string value.digest
        && has_field "platform" value
        && valid_oci_platform value.platform
      else
        false
    )
  )
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
    | doc "Declared payload object hash materialized from `origin`; `result_id` is derived later from `object_hash`.",
  origin
    | SourceOrigin
    | optional
    | doc "Optional source origin. If omitted, the canonical result must already exist in store.",
  ..
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
let FsTreeInstallAttrs = {
  uid | Number | optional,
  gid | Number | optional,
  directory_mode | Number | optional,
  regular_file_mode | Number | optional,
  executable_file_mode | Number | optional,
}
in
let FsTreeInstallRule = {
  path | String,
  attrs
    | FsTreeInstallAttrs
    | doc "Install attributes applied while importing into fs-tree.",
}
in
let FsTreeInstallMeta = {
  rules
    | Array FsTreeInstallRule
    | doc "Install rules used by `FsTreeImport`.",
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
    | doc "Generated tree description staged directly as a plain file or directory.",
}
in
let FsTreeImportConfig = {
  install
    | FsTreeInstallMeta
    | doc "Install rules applied while importing the input tree into fs-tree.",
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
let AutotoolsConfig = {
  configure_args | Array String | optional,
  make_args | Array String | optional,
  env | Dyn | optional,
  "in-tree" | Bool | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
}
in
let MakefileConfig = {
  make_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_build | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
  skip_install | Bool | optional,
}
in
let MesonConfig = {
  setup_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
}
in
let PerlModuleConfig = {
  perl_args | Array String | optional,
  make_args | Array String | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
}
in
let TreeMergeConfig =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let GroupConfig =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let NonEmptyArray =
  std.contract.from_predicate (fun value => std.array.length value > 0)
in
let NonEmptyRecord =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) > 0)
in
let TreeSubsetConfig = {
  include | Array String | NonEmptyArray,
}
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
let InitramfsConfig =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let OciExtractConfig =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let GroupInputsShape = NonEmptyRecord
in
let TreeInputs = {}
in
let FsTreeImportInputsShape = {
  input
    | Dyn
    | doc "Single directory tree input imported into fs-tree.",
}
in
let SandboxBuildRootfsInputsShape = {
  rootfs
    | Dyn
    | doc "Single recipe node for the rootfs directory input.",
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
let TreeSubsetInputsShape = {
  tree
    | Dyn
    | doc "Single fs-tree input to subset.",
}
in
let RootfsClosureInputsShape = { .. }
in
let ErofsRootfsInputsShape = {
  tree
    | Dyn
    | doc "Single fs-tree manifest input used to build an EROFS image.",
}
in
let InitramfsInputsShape = { .. }
in
let SyntheticRootfsInputsShape = {
  rootfs | Dyn,
  source | Dyn,
  ..
}
in
let SyntheticPackageInputsShape = {
  source | Dyn,
  ..
}
in
let SandboxInputsShape = { .. }
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
    if checked.tag == "Group" then
      checked
      & {
        config = checked.config | GroupConfig,
      }
    else if checked.tag == "Tree" then
      checked
      & {
        config = validate_tree_config checked.config,
      }
    else if checked.tag == "FsTreeImport" then
      checked
      & {
        config = checked.config | FsTreeImportConfig,
      }
    else if checked.tag == "AutotoolsRootfs" then
      checked
      & {
        config = checked.config | AutotoolsConfig,
      }
    else if checked.tag == "Autotools" then
      checked
      & {
        config = checked.config | AutotoolsConfig,
        deps = checked.deps | RecipeDeps,
      }
    else if checked.tag == "MakefileRootfs" then
      checked
      & {
        config = checked.config | MakefileConfig,
      }
    else if checked.tag == "Makefile" then
      checked
      & {
        config = checked.config | MakefileConfig,
        deps = checked.deps | RecipeDeps,
      }
    else if checked.tag == "MesonRootfs" then
      checked
      & {
        config = checked.config | MesonConfig,
      }
    else if checked.tag == "Meson" then
      checked
      & {
        config = checked.config | MesonConfig,
        deps = checked.deps | RecipeDeps,
      }
    else if checked.tag == "PerlModuleRootfs" then
      checked
      & {
        config = checked.config | PerlModuleConfig,
      }
    else if checked.tag == "PerlModule" then
      checked
      & {
        config = checked.config | PerlModuleConfig,
        deps = checked.deps | RecipeDeps,
      }
    else if checked.tag == "SandboxBuildRootfs" then
      checked
      & {
        config = checked.config | SandboxConfig,
      }
    else if checked.tag == "SandboxBuild" then
      checked
      & {
        config = checked.config | SandboxConfig,
        deps = checked.deps | RecipeDeps,
      }
    else if checked.tag == "TreeMerge" then
      checked
      & {
        config = checked.config | TreeMergeConfig,
      }
    else if checked.tag == "TreeSubset" then
      checked
      & {
        config = checked.config | TreeSubsetConfig,
      }
    else if checked.tag == "RootfsClosure" then
      checked
      & {
        config = checked.config | TreeMergeConfig,
      }
    else if checked.tag == "ErofsRootfs" then
      checked
      & {
        config = checked.config | ErofsRootfsConfig,
      }
    else if checked.tag == "Initramfs" then
      checked
      & {
        config = checked.config | InitramfsConfig,
      }
    else if checked.tag == "OciExtract" then
      checked
      & {
        config = checked.config | OciExtractConfig,
      }
    else
      checked
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
    let validate_tree_inputs = fun inputs =>
      inputs | TreeInputs
    in
    let validate_group_inputs = fun inputs =>
      let checked = inputs | GroupInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_fs_tree_import_inputs = fun inputs =>
      let checked = inputs | FsTreeImportInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_synthetic_rootfs_inputs = fun inputs =>
      let checked = inputs | SyntheticRootfsInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_synthetic_package_inputs = fun inputs =>
      let checked = inputs | SyntheticPackageInputsShape in
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
      let checked = inputs | SandboxBuildRootfsInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_sandbox_build_inputs = fun inputs =>
      let checked = inputs | SandboxInputsShape in
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
    let validate_tree_subset_inputs = fun inputs =>
      let checked = inputs | TreeSubsetInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    let validate_rootfs_closure_inputs = fun inputs =>
      let checked = inputs | RootfsClosureInputsShape in
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
    let validate_initramfs_inputs = fun inputs =>
      let checked = inputs | InitramfsInputsShape in
      std.record.map
        (fun _ input => ValidateRecipe input)
        checked
    in
    if checked.tag == "Group" then
      checked
      & {
        config = checked.config | GroupConfig,
        inputs = validate_group_inputs checked.inputs,
      }
    else if checked.tag == "Tree" then
      checked
      & {
        config = validate_tree_config checked.config,
        inputs = validate_tree_inputs checked.inputs,
      }
    else if checked.tag == "FsTreeImport" then
      checked
      & {
        config = checked.config | FsTreeImportConfig,
        inputs = validate_fs_tree_import_inputs checked.inputs,
      }
    else if checked.tag == "AutotoolsRootfs" then
      checked
      & {
        config = checked.config | AutotoolsConfig,
        inputs = validate_synthetic_rootfs_inputs checked.inputs,
      }
    else if checked.tag == "Autotools" then
      checked
      & {
        config = checked.config | AutotoolsConfig,
        deps = checked.deps | RecipeDeps,
        inputs = validate_synthetic_package_inputs checked.inputs,
      }
    else if checked.tag == "MakefileRootfs" then
      checked
      & {
        config = checked.config | MakefileConfig,
        inputs = validate_synthetic_rootfs_inputs checked.inputs,
      }
    else if checked.tag == "Makefile" then
      checked
      & {
        config = checked.config | MakefileConfig,
        deps = checked.deps | RecipeDeps,
        inputs = validate_synthetic_package_inputs checked.inputs,
      }
    else if checked.tag == "MesonRootfs" then
      checked
      & {
        config = checked.config | MesonConfig,
        inputs = validate_synthetic_rootfs_inputs checked.inputs,
      }
    else if checked.tag == "Meson" then
      checked
      & {
        config = checked.config | MesonConfig,
        deps = checked.deps | RecipeDeps,
        inputs = validate_synthetic_package_inputs checked.inputs,
      }
    else if checked.tag == "PerlModuleRootfs" then
      checked
      & {
        config = checked.config | PerlModuleConfig,
        inputs = validate_synthetic_rootfs_inputs checked.inputs,
      }
    else if checked.tag == "PerlModule" then
      checked
      & {
        config = checked.config | PerlModuleConfig,
        deps = checked.deps | RecipeDeps,
        inputs = validate_synthetic_package_inputs checked.inputs,
      }
    else if checked.tag == "SandboxBuildRootfs" then
      checked
      & {
        config = checked.config | SandboxConfig,
        inputs = validate_sandbox_inputs checked.inputs,
      }
    else if checked.tag == "SandboxBuild" then
      checked
      & {
        config = checked.config | SandboxConfig,
        deps = checked.deps | RecipeDeps,
        inputs = validate_sandbox_build_inputs checked.inputs,
      }
    else if checked.tag == "TreeMerge" then
      checked
      & {
        config = checked.config | TreeMergeConfig,
        inputs = validate_tree_merge_inputs checked.inputs,
      }
    else if checked.tag == "TreeSubset" then
      checked
      & {
        config = checked.config | TreeSubsetConfig,
        inputs = validate_tree_subset_inputs checked.inputs,
      }
    else if checked.tag == "RootfsClosure" then
      checked
      & {
        config = checked.config | TreeMergeConfig,
        inputs = validate_rootfs_closure_inputs checked.inputs,
      }
    else if checked.tag == "ErofsRootfs" then
      checked
      & {
        config = checked.config | ErofsRootfsConfig,
        inputs = validate_erofs_rootfs_inputs checked.inputs,
      }
    else if checked.tag == "Initramfs" then
      checked
      & {
        config = checked.config | InitramfsConfig,
        inputs = validate_initramfs_inputs checked.inputs,
      }
    else if checked.tag == "OciExtract" then
      checked
      & {
        config = checked.config | OciExtractConfig,
        inputs = validate_oci_extract_inputs checked.inputs,
      }
    else
      checked
in
{
  known_tags
    | Array String
    | doc "Closed set of currently supported recipe builder tags."
    = KnownTags,
  base_recipe
    | doc "Base structural contract shared by all recipe nodes."
    = BaseRecipe,
  group_config
    | doc "Config contract for `Group` recipe nodes."
    = GroupConfig,
  tree_config
    | doc "Config contract for `Tree` recipe nodes."
    = TreeConfig,
  fs_tree_import_config
    | doc "Config contract for `FsTreeImport` recipe nodes."
    = FsTreeImportConfig,
  source_recipe
    | doc "Structural contract for `Source` recipe nodes."
    = SourceRecipe,
  autotools_config
    | doc "Config contract for synthetic `Autotools` and `AutotoolsRootfs` recipe nodes."
    = AutotoolsConfig,
  makefile_config
    | doc "Config contract for synthetic `Makefile` and `MakefileRootfs` recipe nodes."
    = MakefileConfig,
  meson_config
    | doc "Config contract for synthetic `Meson` and `MesonRootfs` recipe nodes."
    = MesonConfig,
  perl_module_config
    | doc "Config contract for synthetic `PerlModule` and `PerlModuleRootfs` recipe nodes."
    = PerlModuleConfig,
  sandbox_config
    | doc "Config contract for synthetic `SandboxBuild` and `SandboxBuildRootfs` recipe nodes."
    = SandboxConfig,
  tree_merge_config
    | doc "Config contract for `TreeMerge` recipe nodes."
    = TreeMergeConfig,
  erofs_rootfs_config
    | doc "Config contract for `ErofsRootfs` recipe nodes."
    = ErofsRootfsConfig,
  initramfs_config
    | doc "Config contract for `Initramfs` recipe nodes."
    = InitramfsConfig,
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
