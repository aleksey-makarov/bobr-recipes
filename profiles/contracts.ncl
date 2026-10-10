# Contracts and validation for build profiles, providers, and publication.
# `Profile` describes the `bobr.ncl` a caller keeps in their
# working directory and normally implements by importing one of the presets in
# this directory.
#
# A profile describes one installation: its final package set, ordered goals,
# where the store is, and optionally where to publish the completed store. It
# is deliberately *not* a request: a request also carries
# the whole node DAG, plus the identity of a single run (`run_id` and its two
# directories), which is minted fresh per invocation and cannot be written down
# in advance. `bin/bobr-build.sh` reads a profile, mints the run, and lowers the
# two together into a request.
#
# Everything except the explicitly required fields is optional. The record is
# closed, so a misspelled field is reported by name instead of being silently
# ignored. Relative paths are resolved against the top-level profile file,
# never the current directory or an imported preset.
let PositiveInteger =
  std.contract.all_of [
    Number,
    std.contract.from_predicate (fun value => std.number.is_integer value && value > 0),
  ]
in
let FixedProgressLines =
  std.contract.all_of [
    Number,
    std.contract.from_predicate (fun value => std.number.is_integer value && value >= 4),
  ]
in
let RetentionDuration =
  std.contract.all_of [
    String,
    std.contract.from_predicate (fun value => std.string.is_match "^[0-9]+([smhd])?$" value),
  ]
in
let NonEmptyGoals =
  std.contract.all_of [
    Array Dyn,
    std.contract.from_predicate (fun value => std.array.length value > 0),
  ]
in
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
let ProgressPolicyContract =
  TaggedUnion
    "mode"
    {
      auto = { mode | std.contract.Equal "auto" },
      summary = { mode | std.contract.Equal "summary" },
      fixed = {
        mode | std.contract.Equal "fixed",
        max_lines | FixedProgressLines,
      },
    }
in
let LocalTransferPolicyContract =
  std.contract.all_of [
    String,
    std.contract.from_predicate (fun value => value == "hardlink" || value == "copy"),
  ]
in
let LocalProviderBackendContract = {
  store
    | String
    | doc "Read-only bobr store path, resolved relative to this profile.",
  transfer
    | LocalTransferPolicyContract
    | doc "Use `hardlink` on matching filesystems or `copy` for independent inodes."
    | optional,
}
in
let RemoteProviderBackendContract = {
  master_url
    | String
    | doc "Absolute HTTPS URL of the signed repository master.",
  trusted_keys
    | Array String
    | doc "Pinned master signing keys, resolved relative to this profile.",
  ca_bundle
    | String
    | doc "Optional HTTPS CA bundle, resolved relative to this profile."
    | default
    = "",
}
in
let SecondaryProviderContract = {
  name
    | String
    | doc "Unique diagnostic name within each enabled capability.",
  mappings
    | Bool
    | doc "Use authoritative BuildKey and ReuseKey mappings from this backend."
    | default
    = false,
  content
    | Bool
    | doc "Use verified object and fs-file content from this backend."
    | default
    = false,
  local | LocalProviderBackendContract | optional,
  remote | RemoteProviderBackendContract | optional,
}
in
let check_secondary_provider = fun entry =>
  let has_local = std.record.has_field "local" entry in
  let has_remote = std.record.has_field "remote" entry in
  if entry.name == "" then
    std.fail_with "secondary provider name must not be empty"
  else if has_local == has_remote then
    std.fail_with "secondary provider '%{entry.name}' must specify exactly one of local or remote"
  else if !entry.mappings && !entry.content then
    std.fail_with "secondary provider '%{entry.name}' must enable mappings, content, or both"
  else if has_local && entry.content && !std.record.has_field "transfer" entry.local then
    std.fail_with "local content provider '%{entry.name}' requires a transfer policy"
  else if has_local && !entry.content && std.record.has_field "transfer" entry.local then
    std.fail_with "local mapping provider '%{entry.name}' must not specify a transfer policy"
  else if has_remote && std.array.length entry.remote.trusted_keys == 0 then
    std.fail_with "remote provider '%{entry.name}' requires at least one trusted key"
  else
    entry
in
let RotationPolicyContract = {
  max_active_content_bytes
    | PositiveInteger
    | doc "Start another slot after the active slot reaches this encoded content size."
    | default
    = 200000000000,
  max_current_slots
    | PositiveInteger
    | doc "Rotate instead of adding a slot after this many current slots exist."
    | default
    = 3,
  retention
    | RetentionDuration
    | doc "Grace period for replaced or rotated slot state: integer seconds or an s/m/h/d suffix."
    | default
    = "1d",
}
in
let OutputRepositoryContract = {
  create_bucket_if_missing
    | Bool
    | doc "Initialize a missing dedicated Bobr bucket before publication."
    | default
    = false,
  repository
    | String
    | doc "S3 bucket and optional prefix used by the authenticated publisher."
    | default
    = "s3://bobr",
  endpoint_url
    | String
    | doc "Optional AWS_ENDPOINT_URL_S3 override."
    | default
    = "",
  region
    | String
    | doc "Optional AWS_REGION override."
    | default
    = "",
  credentials_file
    | String
    | doc "Optional AWS credentials file, resolved relative to this profile."
    | default
    = "",
  credentials_profile
    | String
    | doc "Optional AWS_PROFILE override."
    | default
    = "",
  ca_bundle
    | String
    | doc "Optional CA bundle for both S3 and public HTTPS, resolved relative to this profile."
    | default
    = "",
  master_url
    | String
    | doc "Stable public HTTPS URL of the signed repository master.",
  data_base_url
    | String
    | doc "Public immutable-data URL required for initial publication; empty reads it from an existing signed master."
    | default
    = "",
  trusted_keys
    | Array String
    | doc "Trusted master signing keys; empty selects the recipes' default public key."
    | default
    = [],
  cache
    | String
    | doc "Repository metadata cache; empty selects <store>/repository-cache."
    | default
    = "",
  candidate
    | String
    | doc "Unsigned candidate master path, resolved relative to this profile."
    | default
    = "candidate-master.cbor",
  rotation
    | RotationPolicyContract
    | default
    = {},
}
in
{
  ProgressPolicy = ProgressPolicyContract,
  SecondaryProvider = SecondaryProviderContract,
  validate_secondary_provider = check_secondary_provider,
  RotationPolicy = RotationPolicyContract,
  OutputRepository = OutputRepositoryContract,
  Profile = {
    pkgs
      | Dyn
      | doc "Final package set used to lower the selected recipes.",

    goals
      | NonEmptyGoals
      | doc "Non-empty ordered array of recipe values to realize.",

    store
      | String
      | doc m%"
        The content-addressed store. It must already exist: creating it on
        demand would turn a mistyped path into a silent from-scratch rebuild
        instead of an immediate error.
      "%
      | default
      = "bobr-store",

    logs
      | String
      | doc "Where per-run log directories are made. Defaults to `<store>/logs`."
      | default
      = "",

    work
      | String
      | doc m%"
        Where per-run work directories are made. Defaults to `<store>/work`.
        Must be on the store's filesystem: builds stage their output here and
        the store publishes it by renaming and hardlinking, neither of which
        crosses a filesystem boundary.
      "%
      | default
      = "",

    jobs
      | Number
      | doc m%"
        Cap on builders running at once. 0 leaves the choice to `bobr`, which
        uses the available parallelism.
      "%
      | default
      = 0,

    quiet
      | Bool
      | doc "Suppress the live progress log, leaving warnings and errors."
      | default
      = false,

    progress
      | ProgressPolicyContract
      | doc m%"
        Terminal presentation policy. `auto` derives a line budget from the
        current TTY, `fixed` caps the complete live block at `max_lines`, and
        `summary` hides individual builder rows. It never affects build
        identity and is ignored for non-terminal output.
      "%
      | default
      = { mode = "auto" },

    podman_unshare
      | Bool
      | doc m%"
        Run `bobr` under `podman unshare`. A property of the host -- set it
        where unprivileged user namespaces are unavailable.
      "%
      | default
      = false,

    fetch
      | {
        per_host_default | Number | default = 0,
        per_host | { _ : Number } | default = {},
        max_connections | Number | default = 0,
        max_local_jobs | Number | default = 0,
      }
      | doc m%"
        Acquisition limits for `bobr`. `per_host_default` caps downloads per
        host (0 leaves bobr's default of 6), `per_host` overrides it for named
        hosts, `max_connections` caps downloads in flight overall (0 derives it
        from the file-descriptor limit), and `max_local_jobs` is one shared
        limit for local Source work, repository content transfer and
        verification, and builder input preparation.
      "%
      | default
      = {},

    secondaries
      | {
        repository_cache
          | String
          | doc "Remote repository metadata cache; empty selects <store>/repository-cache."
          | default
          = "",
        providers
          | Array SecondaryProviderContract
          | default
          = [],
      }
      | doc m%"
        Ordered local and remote secondary backends. `mappings` enables
        authoritative BuildKey/ReuseKey lookup and `content` enables verified
        content acquisition; enabling both is shorthand for two independent
        request capabilities backed by the same source. Local content requires
        an explicit `hardlink` or `copy` transfer policy. Paths are resolved
        relative to this profile.
      "%
      | default
      = {},

    output_repository
      | OutputRepositoryContract
      | doc m%"
        Optional post-build publication destination. This configuration is
        resolved by the build driver and never enters the Bobr build request.
      "%
      | optional,
  },
}
