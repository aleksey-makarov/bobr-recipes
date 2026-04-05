let Kind = fun expected => std.contract.Equal expected in
let Sha256Digest =
  std.contract.from_predicate (fun value => std.string.is_match "^sha256:[0-9a-f]{64}$" value)
in
let KnownKinds = [
  "plain-text",
  "build-script",
  "source-tree",
  "fetched-file",
  "container-image",
  "binary-output",
]
in
let KnownKind =
  std.contract.from_validator (
    fun label value =>
      if std.array.elem value KnownKinds then
        'Ok value
      else
        'Error "expected one of the known metadata kinds"
  )
in
let MetaWithKind = {
  kind
    | String
    | doc "Object metadata kind discriminator.",
  ..
}
in
let PlainTextMeta = {
  kind
    | Kind "plain-text"
    | doc "Metadata kind for plain text objects.",
}
in
let BuildScriptMeta = {
  kind
    | Kind "build-script"
    | doc "Metadata kind for executable build scripts.",
}
in
let SourceTreeMeta = {
  kind
    | Kind "source-tree"
    | doc "Metadata kind for unpacked source trees.",
}
in
let FetchedFileMeta = {
  kind
    | Kind "fetched-file"
    | doc "Metadata kind for fetched single-file payloads.",
}
in
let ContainerImageMeta = {
  kind
    | Kind "container-image"
    | doc "Metadata kind for OCI image layout objects.",
  manifest_digest
    | String
    | Sha256Digest
    | doc "Digest of the OCI manifest blob stored in the object.",
}
in
let BinaryOutputOwner = {
  path
    | String
    | doc "Install path selector for matching output paths.",
  uid
    | Number
    | doc "Target user id for matching installed paths.",
  gid
    | Number
    | doc "Target group id for matching installed paths.",
}
in
let BinaryOutputInstall = {
  owners
    | Array BinaryOutputOwner
    | doc "Ownership rules applied when the object is installed.",
}
in
let BinaryOutputMeta = {
  kind
    | Kind "binary-output"
    | doc "Metadata kind for installable filesystem trees.",
  install
    | BinaryOutputInstall
    | doc "Installation metadata attached to this output tree.",
}
in
let KindContracts = {
  "plain-text" = PlainTextMeta,
  "build-script" = BuildScriptMeta,
  "source-tree" = SourceTreeMeta,
  "fetched-file" = FetchedFileMeta,
  "container-image" = ContainerImageMeta,
  "binary-output" = BinaryOutputMeta,
}
in
{
  known_kinds
    | Array String
    | doc "Closed set of currently recognized object metadata kinds."
    = KnownKinds,
  plain_text_meta
    | doc "Contract for `meta` of plain-text objects."
    = PlainTextMeta,
  build_script_meta
    | doc "Contract for `meta` of build-script objects."
    = BuildScriptMeta,
  source_tree_meta
    | doc "Contract for `meta` of source-tree objects."
    = SourceTreeMeta,
  fetched_file_meta
    | doc "Contract for `meta` of fetched-file objects."
    = FetchedFileMeta,
  container_image_meta
    | doc "Contract for `meta` of container-image objects."
    = ContainerImageMeta,
  binary_output_meta
    | doc "Contract for `meta` of binary-output objects."
    = BinaryOutputMeta,
  validate_meta
    | doc "Validate a metadata record against the contract selected by `meta.kind`."
    = fun meta =>
      let checked = meta | MetaWithKind in
      let _ = checked.kind | KnownKind in
      checked | KindContracts."%{checked.kind}",
}
