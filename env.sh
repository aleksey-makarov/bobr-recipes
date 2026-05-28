#!/usr/bin/env bash

# Shared environment for recipe-side tools.
# Edit `store_rel_from_recipes` if you want to move the local mbuild store.
# Store paths are interpreted relative to the `mbuild-recipes` checkout root.

store_rel_from_recipes="../mbuild-store"

env_sh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_root="${env_sh_dir}"
workspace_root="$(cd "${recipes_root}/.." && pwd)"
store_root="$(realpath -m "${recipes_root}/${store_rel_from_recipes}")"
