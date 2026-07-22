# Recipe-node contracts and validators.
#
# The single source of truth is `tag_specs` below: one row per builder tag,
# holding the tag's config contract, its inputs shape, and whether the tag
# requires Nickel-level `deps`. `known_tags` and both validators (shallow and
# deep) derive from that table -- adding a builder tag is one table row, with
# no parallel lists to keep in sync and no silent fallthrough for a forgotten
# tag.

# --- small shared contracts --------------------------------------------------

let NonEmptyArray =
  std.contract.from_predicate (fun value => std.array.length value > 0)
in
let NonEmptyRecord =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) > 0)
in
let NonEmptyString =
  std.contract.from_predicate (fun value => std.is_string value && value != "")
in
# Shared by every tag whose builder takes no configuration.
let EmptyConfig =
  std.contract.from_predicate (fun value =>
    std.is_record value
    && std.array.length (std.record.fields value) == 0
  )
in
# Dispatch a record contract on a string discriminator field. Delegates to the
# matching variant via `std.contract.check`, so blame points at the offending
# field of the variant contract instead of at the whole union.
let TaggedUnion = fun discriminator =>
  fun variants =>
    std.contract.custom (fun label value =>
      if !std.is_record value then
        'Error { message = "expected a record" }
      else if !std.record.has_field discriminator value then
        'Error { message = "missing discriminator field '%{discriminator}'" }
      else
        let tag = std.record.get discriminator value in
        if !std.is_string tag then
          'Error { message = "discriminator field '%{discriminator}' must be a string" }
        else if std.record.has_field tag variants then
          std.contract.check (std.record.get tag variants) label value
        else
          'Error {
            message = "unknown %{discriminator} '%{tag}'; expected one of: %{std.string.join ", " (std.record.fields variants)}",
          }
    )
in

let RecipeDeps = {
  build | Array Dyn,
  runtime | Array Dyn,
}
in

# --- Source origins ----------------------------------------------------------

let ArchiveFormat =
  std.contract.from_predicate (fun value => std.array.elem value ["tar-gz", "tar-xz", "tar-bz2", "zip"])
in
let UrlField =
  std.contract.any_of [
    String,
    std.contract.all_of [Array String, NonEmptyArray],
  ]
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
    | doc "HTTP(S) source URL or non-empty list of fallback URLs.",
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
    | NonEmptyString
    | doc "OCI platform operating system, for example `linux`.",
  architecture
    | NonEmptyString
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
let SourceOrigin =
  TaggedUnion
    "tag"
    {
      Path = SourcePathOrigin,
      RecipePath = SourceRecipePathOrigin,
      Http = SourceHttpOrigin,
      OciRegistry = SourceOciRegistryOrigin,
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
    | doc "Declared payload object hash materialized from `origin`; `result_id` is derived later from `object_hash`.",
  origin
    | SourceOrigin
    | optional
    | doc "Optional source origin. If omitted, the canonical result must already exist in store.",
  ..
}
in

# --- per-tag config contracts ------------------------------------------------

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
let TreeEntry =
  TaggedUnion
    "type"
    {
      file = TreeFileEntry,
      dir = TreeDirEntry,
      symlink = TreeSymlinkEntry,
    }
in
let TreeConfig = {
  tree
    | {
      entries
        | Array TreeEntry
        | doc "Generated tree entries describing text files, explicit directories, and symlinks.",
    }
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
  in-tree | Bool | optional,
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
let PythonModuleConfig = {
  env | Dyn | optional,
  source_subdir | String | optional,
  pre_configure | AutotoolsHook | optional,
  post_install | AutotoolsHook | optional,
}
in
let CargoConfig = {
  features | Array String | optional,
  bins | Array String | optional,
  no_default_features | Bool | optional,
  env | Dyn | optional,
  source_subdir | String | optional,
  post_install | AutotoolsHook | optional,
}
in
let TreeSubsetConfig = {
  include | Array String | NonEmptyArray,
}
in
let TreeMoveConfig = {
  strip_prefix
    | String
    | doc "Subdirectory to re-root the input tree at (its leading path component is stripped).",
}
in
let FsTreeExportConfig = {
  copies
    | Array {
      from | String,
      to | String,
    }
    | NonEmptyArray
    | doc "Copy commands exporting fs-tree entries into a plain object.",
}
in

# --- per-tag inputs shapes (checked by the deep validator only) --------------

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
let FsTreeExportInputsShape = {
  input
    | Dyn
    | doc "Single fs-tree node whose entries are exported to a plain object.",
}
in
let SandboxRootfsInputsShape = {
  _rootfs
    | Dyn
    | doc "Single materialized fs-tree node for the rootfs directory input.",
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
let TreeMoveInputsShape = {
  tree
    | Dyn
    | doc "Single fs-tree input to re-root.",
}
in
let RootfsClosureInputsShape = { .. }
in
let InitramfsInputsShape = { .. }
in
let SyntheticRootfsInputsShape = {
  _rootfs | Dyn,
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

# --- the tag table -----------------------------------------------------------

# One row per non-`Source` builder tag. `requires_deps` marks the
# dependency-aware synthetic package tags whose recipes must declare
# Nickel-level `deps` (the *Rootfs/Stage* variants supply their own `_rootfs`
# instead).
let tag_specs = {
  Group = { config = EmptyConfig, inputs = GroupInputsShape, requires_deps = false },
  Tree = { config = TreeConfig, inputs = TreeInputs, requires_deps = false },
  FsTreeImport = { config = FsTreeImportConfig, inputs = FsTreeImportInputsShape, requires_deps = false },
  FsTreeExport = { config = FsTreeExportConfig, inputs = FsTreeExportInputsShape, requires_deps = false },
  TreeMerge = { config = EmptyConfig, inputs = TreeMergeInputsShape, requires_deps = false },
  TreeSubset = { config = TreeSubsetConfig, inputs = TreeSubsetInputsShape, requires_deps = false },
  TreeMove = { config = TreeMoveConfig, inputs = TreeMoveInputsShape, requires_deps = false },
  RootfsClosure = { config = EmptyConfig, inputs = RootfsClosureInputsShape, requires_deps = false },
  Initramfs = { config = EmptyConfig, inputs = InitramfsInputsShape, requires_deps = false },
  OciExtract = { config = EmptyConfig, inputs = OciExtractInputsShape, requires_deps = false },
  Bundle = { config = EmptyConfig, inputs = GroupInputsShape, requires_deps = false },
  Autotools = { config = AutotoolsConfig, inputs = SyntheticPackageInputsShape, requires_deps = true },
  AutotoolsStageRootfs = { config = AutotoolsConfig, inputs = SyntheticRootfsInputsShape, requires_deps = false },
  Makefile = { config = MakefileConfig, inputs = SyntheticPackageInputsShape, requires_deps = true },
  MakefileStageRootfs = { config = MakefileConfig, inputs = SyntheticRootfsInputsShape, requires_deps = false },
  Meson = { config = MesonConfig, inputs = SyntheticPackageInputsShape, requires_deps = true },
  MesonRootfs = { config = MesonConfig, inputs = SyntheticRootfsInputsShape, requires_deps = false },
  PerlModule = { config = PerlModuleConfig, inputs = SyntheticPackageInputsShape, requires_deps = true },
  PythonModule = { config = PythonModuleConfig, inputs = SyntheticPackageInputsShape, requires_deps = true },
  Cargo = { config = CargoConfig, inputs = SyntheticPackageInputsShape, requires_deps = true },
  CargoRootfs = { config = CargoConfig, inputs = SyntheticRootfsInputsShape, requires_deps = false },
  Sandbox = { config = SandboxConfig, inputs = SandboxRootfsInputsShape, requires_deps = false },
  SandboxInstall = { config = SandboxConfig, inputs = SandboxRootfsInputsShape, requires_deps = false },
  SandboxStageRootfs = { config = SandboxConfig, inputs = SandboxRootfsInputsShape, requires_deps = false },
  SandboxInstallDeps = { config = SandboxConfig, inputs = SandboxInputsShape, requires_deps = true },
  SandboxStageDeps = { config = SandboxConfig, inputs = SandboxInputsShape, requires_deps = true },
}
in
let KnownTags = ["Source"] @ std.record.fields tag_specs
in
let KnownTag =
  std.contract.from_predicate (fun value => std.array.elem value KnownTags)
in

# --- top-level recipe shapes -------------------------------------------------

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

# --- validators --------------------------------------------------------------

# The tag-specific refinement of a base-checked node: validate `config`
# against the tag's contract and require `deps` where the tag mandates it.
# Open (`..`): the base contracts already govern the rest of the node.
let node_spec_contract = fun spec =>
  if spec.requires_deps then
    { config | spec.config, deps | RecipeDeps, .. }
  else
    { config | spec.config, .. }
in
let ValidateRecipeShallow = fun recipe =>
  if recipe.tag == "Source" then
    recipe | SourceRecipe
  else
    let checked = recipe | ShallowBaseRecipe in
    checked | node_spec_contract (std.record.get checked.tag tag_specs)
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
    let spec = std.record.get checked.tag tag_specs in
    let node_checked = checked | node_spec_contract spec in
    std.record.update
      "inputs"
      (
        std.record.map
          (fun _ input => ValidateRecipe input)
          (node_checked.inputs | spec.inputs)
      )
      node_checked
in
{
  known_tags
    | Array String
    | doc "Closed set of currently supported recipe builder tags, derived from the tag table."
    = KnownTags,
  base_recipe
    | doc "Base structural contract shared by all recipe nodes."
    = BaseRecipe,
  group_config
    | doc "Config contract for `Group` recipe nodes."
    = EmptyConfig,
  tree_config
    | doc "Config contract for `Tree` recipe nodes."
    = TreeConfig,
  fs_tree_import_config
    | doc "Config contract for `FsTreeImport` recipe nodes."
    = FsTreeImportConfig,
  fs_tree_export_config
    | doc "Config contract for `FsTreeExport` recipe nodes."
    = FsTreeExportConfig,
  source_recipe
    | doc "Structural contract for `Source` recipe nodes."
    = SourceRecipe,
  autotools_config
    | doc "Config contract for synthetic `Autotools` and `AutotoolsStageRootfs` recipe nodes."
    = AutotoolsConfig,
  makefile_config
    | doc "Config contract for synthetic `Makefile` and `MakefileStageRootfs` recipe nodes."
    = MakefileConfig,
  meson_config
    | doc "Config contract for synthetic `Meson` and `MesonRootfs` recipe nodes."
    = MesonConfig,
  perl_module_config
    | doc "Config contract for synthetic `PerlModule` recipe nodes."
    = PerlModuleConfig,
  python_module_config
    | doc "Config contract for synthetic `PythonModule` recipe nodes."
    = PythonModuleConfig,
  cargo_config
    | doc "Config contract for synthetic `Cargo` and `CargoRootfs` recipe nodes."
    = CargoConfig,
  sandbox_config
    | doc "Config contract for the low-level `Sandbox`/`SandboxInstall` builders and their synthetic `*StageRootfs`/`*Build` variants."
    = SandboxConfig,
  tree_merge_config
    | doc "Config contract for `TreeMerge` recipe nodes."
    = EmptyConfig,
  initramfs_config
    | doc "Config contract for `Initramfs` recipe nodes."
    = EmptyConfig,
  oci_extract_config
    | doc "Config contract for `OciExtract` recipe nodes."
    = EmptyConfig,
  bundle_config
    | doc "Config contract for `Bundle` recipe nodes."
    = EmptyConfig,
  shallow_recipe
    | doc m%"
        Validate one recipe node shallowly: full top-level shape and
        tag-specific config, but leave the graph-carrying fields (`inputs`,
        `deps`) unvalidated -- they hold whole nested node graphs, and forcing
        them would unfold the shared recipe DAG into a tree.

        The leaf data (`name`, `tag`, `config`, and `origin` for `Source`
        nodes) is forced through `std.serialize`, which triggers the delayed
        record-contract checks. A lazy `let`-binding would NOT run them:
        an unused binding is never evaluated. (`std.deep_seq` is unusable
        here twice over: it would force `inputs`, and nickel 1.17 panics on
        deep_seq of a record with an undefined optional contract field.)
      "%
    =
      std.contract.from_predicate (fun recipe =>
        let checked = ValidateRecipeShallow recipe in
        let forced =
          if recipe.tag == "Source" then
            { name = checked.name, object_hash = checked.object_hash }
            & (
              if std.record.has_field "origin" checked then
                { origin = checked.origin }
              else
                {}
            )
          else
            { name = checked.name, tag = checked.tag, config = checked.config }
        in
        std.seq (std.serialize 'Json forced) true
      ),
  validate_recipe
    | doc "WARNING: deep recursive validation. This walks the entire nested recipe graph and is expensive on large raw package sets."
    = ValidateRecipe,
}
