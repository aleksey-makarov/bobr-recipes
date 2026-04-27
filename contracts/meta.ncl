let Sha256Digest =
  std.contract.from_predicate (fun value => std.string.is_match "^sha256:[0-9a-f]{64}$" value)
in
let EmptyRecord =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let InstallAttrs = {
  uid
    | Number
    | optional
    | doc "Target user id for matching installed paths.",
  gid
    | Number
    | optional
    | doc "Target group id for matching installed paths.",
  directory_mode
    | Number
    | optional
    | doc "Final unix mode for matching installed directories.",
  regular_file_mode
    | Number
    | optional
    | doc "Final unix mode for matching non-executable regular files.",
  executable_file_mode
    | Number
    | optional
    | doc "Final unix mode for matching executable regular files.",
  symlink_mode
    | Number
    | optional
    | doc "Final unix mode for matching symlinks.",
}
in
let InstallRule = {
  path
    | String
    | doc "Install path selector for matching output paths.",
  attrs
    | InstallAttrs
    | doc "Install attributes overridden for matching output paths.",
}
in
let InstallMetadata = {
  rules
    | Array InstallRule
    | doc "Path rules applied when the object is installed.",
}
in
let InstallMeta = {
  install
    | InstallMetadata
    | doc "Installation metadata attached to this output tree.",
}
in
let MetaRecord = { .. }
in
{
  empty_meta
    | doc "Contract for objects without extra metadata."
    = EmptyRecord,
  install_meta
    | doc "Contract for installable filesystem tree metadata."
    = InstallMeta,
  validate_meta
    | doc "Validate a metadata record against the current closed metadata shapes."
    = fun meta =>
      let checked = meta | MetaRecord in
      if std.record.has_field "install" checked then
        checked | InstallMeta
      else
        checked | EmptyRecord,
}
