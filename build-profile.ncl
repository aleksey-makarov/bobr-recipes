# Contract for a build profile -- the `bobr.ncl` a caller keeps in their working
# directory (start from `bobr.ncl.example`).
#
# A profile describes one installation: where the store is, what to build by
# default, which overlays to apply. It is deliberately *not* a request: a request
# also carries the whole node DAG, plus the identity of a single run (`run_id`
# and its two directories), which is minted fresh per invocation and so cannot be
# written down in advance. `bin/bobr-build.sh` reads a profile, mints the run,
# and lowers the two together into a request.
#
# Everything is optional; the defaults below are what a caller gets by writing
# `{}`. The record is closed, so a misspelled field is reported by name instead
# of being silently ignored. Relative paths are resolved against the profile file itself, never the
# current directory, so the same profile means the same thing wherever it is
# invoked from.
let FixedProgressLines =
  std.contract.all_of [
    Number,
    std.contract.from_predicate (fun value => value >= 4),
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
  TaggedUnion "mode" {
    auto = { mode | std.contract.Equal "auto" },
    summary = { mode | std.contract.Equal "summary" },
    fixed = {
      mode | std.contract.Equal "fixed",
      max_lines | FixedProgressLines,
    },
  }
in
{
  ProgressPolicy = ProgressPolicyContract,
  Profile = {
    target
      | String
      | doc m%"
        Recipe attribute to build when the command line does not name one
        (`--target`). An empty value means the caller must always name it.
      "%
      | default = "",

    store
      | String
      | doc m%"
        The content-addressed store. It must already exist: creating it on
        demand would turn a mistyped path into a silent from-scratch rebuild
        instead of an immediate error.
      "%
      | default = "bobr-store",

    logs
      | String
      | doc m%"
        Where per-run log directories are made. Defaults to `<store>/logs`.
      "%
      | default = "",

    work
      | String
      | doc m%"
        Where per-run work directories are made. Defaults to `<store>/work`.
        Must be on the store's filesystem: builds stage their output here and
        the store publishes it by renaming and hardlinking, neither of which
        crosses a filesystem boundary.
      "%
      | default = "",

    overlays
      | Array String
      | doc m%"
        Files to layer over the recipe set, applied in order. Each evaluates to
        either a single overlay or an array of them; both are accepted.
      "%
      | default = [],

    jobs
      | Number
      | doc m%"
        Cap on builders running at once. 0 leaves the choice to `bobr`, which
        uses the available parallelism.
      "%
      | default = 0,

    quiet
      | Bool
      | doc "Suppress the live progress log, leaving warnings and errors."
      | default = false,

    progress
      | ProgressPolicyContract
      | doc m%"
        Terminal presentation policy. `auto` derives a line budget from the
        current TTY, `fixed` caps the complete live block at `max_lines`, and
        `summary` hides individual builder rows. It never affects build
        identity and is ignored for non-terminal output.
      "%
      | default = { mode = "auto" },

    podman_unshare
      | Bool
      | doc m%"
        Run `bobr` under `podman unshare`. A property of the host -- set it
        where unprivileged user namespaces are unavailable.
      "%
      | default = false,

    fetch
      | {
        per_host_default | Number | default = 0,
        per_host | { _ : Number } | default = {},
        max_connections | Number | default = 0,
        max_local_jobs | Number | default = 0,
      }
      | doc m%"
        Acquisition limits for `bobr`. `per_host_default` caps
        downloads per host (0 leaves bobr's default of 6), `per_host`
        overrides it for named hosts, `max_connections` caps downloads in
        flight overall (0 derives it from the file-descriptor limit), and
        `max_local_jobs` caps local Source acquisition/materialization.
      "%
      | default = {},

    secondaries
      | {
        trusted_indexes
          | Array { name | String, store | String }
          | default = [],
        content_sources
          | Array { name | String, store | String }
          | default = [],
      }
      | doc m%"
        Ordered local secondary capabilities. Paths are resolved relative to
        this profile. A store may appear in both arrays under the same name;
        trusted mapping lookup and hardlink content acquisition remain
        independent capabilities.
      "%
      | default = {},
  },
}
