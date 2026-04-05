let OneOfStrings = fun values =>
  std.contract.from_predicate (fun value => std.array.elem value values)
in
let Sha256Digest =
  std.contract.from_predicate (fun value => std.string.is_match "^sha256:[0-9a-f]{64}$" value)
in
let plain_text_meta_contract = {
  kind | std.contract.Equal "plain-text",
}
in
let build_script_meta_contract = {
  kind | std.contract.Equal "build-script",
}
in
let source_tree_meta_contract = {
  kind | std.contract.Equal "source-tree",
}
in
let fetched_file_meta_contract = {
  kind | std.contract.Equal "fetched-file",
}
in
let container_image_meta_contract = {
  kind | std.contract.Equal "container-image",
  manifest_digest | String | Sha256Digest,
}
in
let binary_output_meta_contract = {
  kind | std.contract.Equal "binary-output",
  install | {
    owners | Array {
      path | String,
      uid | Number,
      gid | Number,
    },
  },
}
in
let known_kinds = [
  "plain-text",
  "build-script",
  "source-tree",
  "fetched-file",
  "container-image",
  "binary-output",
]
in
{
  known_kinds = known_kinds,
  plain_text_meta = plain_text_meta_contract,
  build_script_meta = build_script_meta_contract,
  source_tree_meta = source_tree_meta_contract,
  fetched_file_meta = fetched_file_meta_contract,
  container_image_meta = container_image_meta_contract,
  binary_output_meta = binary_output_meta_contract,
  validate_meta = fun meta =>
    let base = meta | { kind | String, .. } in
    let _ = base.kind | OneOfStrings known_kinds in
    if base.kind == "plain-text" then
      base | plain_text_meta_contract
    else
    if base.kind == "build-script" then
      base | build_script_meta_contract
    else
    if base.kind == "source-tree" then
      base | source_tree_meta_contract
    else
    if base.kind == "fetched-file" then
      base | fetched_file_meta_contract
    else
    if base.kind == "container-image" then
      base | container_image_meta_contract
    else
      base | binary_output_meta_contract,
}
