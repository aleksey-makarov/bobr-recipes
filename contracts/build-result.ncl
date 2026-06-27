let LowerHex64 =
  std.contract.from_predicate (fun value => std.string.is_match "^[0-9a-f]{64}$" value)
in
let ResultId = LowerHex64 in
let ObjectHash = LowerHex64 in
let ResultInputIdentity = {
  object_hash
    | String
    | ObjectHash
    | doc "Payload object hash of one direct input.",
}
in
let ResultRecord = {
  schema
    | std.contract.Equal "bobr-result-v4"
    | doc "Current result record schema identifier.",
  result_id
    | String
    | ResultId
    | doc "Canonical result id for this realized result.",
  object_hash
    | String
    | ObjectHash
    | doc "Payload object hash for the realized result payload.",
  created_at
    | String
    | optional
    | doc "Creation timestamp recorded by the store, if present.",
  inputs
    | Array ResultInputIdentity
    | doc "Direct input identities used to compute this result.",
}
in
{
  result_input_identity
    | doc "Contract for one direct input identity in a result record."
    = ResultInputIdentity,
  result_record
    | doc "Shape contract for one current `bobr-result-v4` record."
    = ResultRecord,
  validate_result
    | doc "Validate one result record."
    = fun result => result | ResultRecord,
}
