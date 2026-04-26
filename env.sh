#!/usr/bin/env bash

# Shared environment for recipe-side tools.
# Edit `store_rel_from_recipes` if you want to move the local mbuild store.
# Edit `local_rel_from_recipes` if you want local source paths to resolve from
# a different base. Both paths are interpreted relative to the
# `mbuild-recipes` checkout root.

store_rel_from_recipes="../mbuild-store"
local_rel_from_recipes="."

env_sh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_root="${env_sh_dir}"
workspace_root="$(cd "${recipes_root}/.." && pwd)"
store_root="$(realpath -m "${recipes_root}/${store_rel_from_recipes}")"
local_root="$(realpath -m "${recipes_root}/${local_rel_from_recipes}")"
