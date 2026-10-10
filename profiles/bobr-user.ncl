# Standard interactive Bobr profile.
#
# Do not copy this file. Import it from `bobr.ncl` in the directory where the
# store should live:
#
#     let bobrpkgs = import "bobr-recipes/bobrpkgs.ncl" in
#     let pkgs = bobrpkgs [] in
#     (import "bobr-recipes/profiles/bobr-user.ncl") & {
#       include pkgs,
#       goals = [pkgs.world],
#     }
#
# The values use a merge priority between contract defaults and ordinary user
# fields, so a local profile can override them without copying the preset:
#
#     let bobrpkgs = import "bobr-recipes/bobrpkgs.ncl" in
#     let pkgs = bobrpkgs [] in
#     (import "bobr-recipes/profiles/bobr-user.ncl") & {
#       include pkgs,
#       goals = [pkgs.world],
#       store = "another-store",
#       jobs = 8,
#     }
#
# Relative paths are resolved against that top-level `bobr.ncl`, not this
# imported file.
{
  # The store. Create it yourself: a mistyped path must fail instead of
  # silently starting a from-scratch rebuild elsewhere.
  store | priority -50 = "bobr-store",

  # Downloads per host normally default to 6. GitLab's archive URLs build a
  # tarball per request and reliably need a lower concurrency limit.
  fetch.per_host."gitlab.freedesktop.org" | priority -50 = 2,

  # Other useful local overrides include:
  #
  # logs = "bobr-store/logs",
  # work = "bobr-store/work",
  # jobs = 8,
  # quiet = true,
  # progress = { mode = "fixed", max_lines = 8 },
  # podman_unshare = true,
  # secondaries = {
  #   providers = [{
  #     name = "previous",
  #     mappings = true,
  #     content = true,
  #     local = {
  #       store = "../old-store",
  #       transfer = "hardlink",
  #     },
  #   }],
  # },
}
