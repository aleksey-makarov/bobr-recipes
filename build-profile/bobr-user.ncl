# Standard interactive Bobr profile.
#
# Do not copy this file. Import it from `bobr.ncl` in the directory where the
# store should live:
#
#     import "bobr-recipes/build-profile/bobr-user.ncl"
#
# The values use a merge priority between contract defaults and ordinary user
# fields, so a local profile can override them without copying the preset:
#
#     (import "bobr-recipes/build-profile/bobr-user.ncl") & {
#       store = "another-store",
#       jobs = 8,
#     }
#
# Relative paths are resolved against that top-level `bobr.ncl`, not this
# imported file.
{
  # What to build when the command line does not say (`--target NAME`).
  target | priority -50 = "world",

  # The store. Create it yourself: a mistyped path must fail instead of
  # silently starting a from-scratch rebuild elsewhere.
  store | priority -50 = "bobr-store",

  # Downloads per host normally default to 6. GitLab's archive URLs build a
  # tarball per request and reliably need a lower concurrency limit.
  fetch | priority -50 = {
    per_host = { "gitlab.freedesktop.org" = 2 },
  },

  # Other useful local overrides include:
  #
  # logs = "bobr-store/logs",
  # work = "bobr-store/work",
  # overlays = ["./my-overlay.ncl"],
  # jobs = 8,
  # quiet = true,
  # progress = { mode = "fixed", max_lines = 8 },
  # podman_unshare = true,
  # secondaries = {
  #   local_repositories = [{
  #     name = "previous",
  #     store = "../old-store",
  #     trusted = true,
  #     transfer = "hardlink",
  #   }],
  # },
}
