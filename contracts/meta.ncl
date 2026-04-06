let Sha256Digest =
  std.contract.from_predicate (fun value => std.string.is_match "^sha256:[0-9a-f]{64}$" value)
in
let EmptyRecord =
  std.contract.from_predicate (fun value => std.array.length (std.record.fields value) == 0)
in
let InstallOwner = {
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
let InstallMetadata = {
  owners
    | Array InstallOwner
    | doc "Ownership rules applied when the object is installed.",
}
in
let InstallMeta = {
  install
    | InstallMetadata
    | doc "Installation metadata attached to this output tree.",
}
in
let ManifestDigestMeta = {
  manifest_digest
    | String
    | Sha256Digest
    | doc "Digest of the OCI manifest blob stored in the object.",
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
  manifest_digest_meta
    | doc "Contract for OCI image metadata carrying a manifest digest."
    = ManifestDigestMeta,
  validate_meta
    | doc "Validate a metadata record against the current closed metadata shapes."
    = fun meta =>
      let checked = meta | MetaRecord in
      if std.record.has_field "install" checked then
        checked | InstallMeta
      else if std.record.has_field "manifest_digest" checked then
        checked | ManifestDigestMeta
      else
        checked | EmptyRecord,
}
