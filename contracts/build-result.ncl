let meta_contracts = import "./meta.ncl" in
let LowerHex64 =
  std.contract.from_predicate (fun value => std.string.is_match "^[0-9a-f]{64}$" value)
in
let ResultKey = LowerHex64 in
let ObjectHash = LowerHex64 in
let MetaHash = LowerHex64 in
let ResultInputIdentity = {
  object_hash
    | String
    | ObjectHash
    | doc "Payload object hash of one direct input.",
  meta_hash
    | String
    | MetaHash
    | doc "Metadata hash of one direct input.",
}
in
let ResultRecord = {
  schema
    | std.contract.Equal "mbuild-result-v3"
    | doc "Current result record schema identifier.",
  result_key
    | String
    | ResultKey
    | doc "Canonical result key for this realized result.",
  object_hash
    | String
    | ObjectHash
    | doc "Payload object hash for the realized result payload.",
  meta_hash
    | String
    | MetaHash
    | doc "Metadata hash for the realized result metadata.",
  created_at
    | String
    | optional
    | doc "Creation timestamp recorded by the store, if present.",
  inputs
    | Array ResultInputIdentity
    | doc "Direct input identities used to compute this result.",
  meta
    | { .. }
    | doc "Object metadata record for the realized payload.",
}
in
{
  result_input_identity
    | doc "Contract for one direct input identity in a result record."
    = ResultInputIdentity,
  result_record
    | doc "Shape contract for one current `mbuild-result-v3` record."
    = ResultRecord,
  validate_result
    | doc "Validate one result record and its nested `meta` payload."
    = fun result =>
      let checked = result | ResultRecord in
      let validated_meta = meta_contracts.validate_meta checked.meta in
      checked & { meta = validated_meta },
}
