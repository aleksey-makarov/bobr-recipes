#!/usr/bin/env bash

# Shared environment for recipe-side tools.
# Edit `store_rel_from_recipes` if you want to move the local bobr store.
# Store paths are interpreted relative to the `bobr-recipes` checkout root.

store_rel_from_recipes="../bobr-store"

env_sh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
recipes_root="${env_sh_dir}"
workspace_root="$(cd "${recipes_root}/.." && pwd)"
store_root="$(realpath -ms "${recipes_root}/${store_rel_from_recipes}")"
