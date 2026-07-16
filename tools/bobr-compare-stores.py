#!/usr/bin/env python3
"""Catch reproducibility issues: find builds that produced different output from
the same inputs across two stores.

Compare two bobr stores built by rebuild-world.sh.

Usage:
    compare-stores.py STORE_A STORE_B [options]

What it does (never aborts on a mismatch -- it reports and continues):
  1. Compares hashes.txt (mbuild / mbuild-recipes commits).
  2. Compares the set of Build Keys (builds/<key>); reports keys present in
     only one store.
  3. On the build keys present in BOTH, compares the produced object hash.
     A divergence is classified as:
       - ROOT     : the build's inputs (input object hashes) are identical in
                    both stores, yet the output differs -> the build step
                    itself is non-deterministic here.
       - inherited: the inputs already differ -> divergence comes from upstream.
     Root divergences are the actionable ones and are reported in detail,
     including which files inside the object differ.

Exit code: 0 if no object-hash divergences among common build keys, else 1.

Store layout used:
  hashes.txt                      "mbuild <sha>" / "mbuild-recipes <sha>"
  builds/<build_key>              {"inputs":[obj_hash...], "object_hash":...}
  object-refs/<name>              symlink -> ../objects/<object_hash>
  objects/<obj_hash>              either an fs-tree manifest (newline-delimited
                                  JSON file: schema header then one entry per
                                  line keyed by "p"; t=f/d/l, h/m/u/g/x by type)
                                  or a plain-object directory of real files
                                  (reports, EROFS images, ...)
  request.json (optional)         {"nodes": {"n1": {"name","tag",...}, ...}}
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path


# -----------------------------------------------------------------------------
# loading
# -----------------------------------------------------------------------------

def load_hashes(store: Path) -> dict[str, str]:
    """Parse hashes.txt into {repo: sha}. Missing file -> empty dict."""
    path = store / "hashes.txt"
    result: dict[str, str] = {}
    if not path.is_file():
        return result
    for line in path.read_text().splitlines():
        parts = line.split()
        if len(parts) >= 2:
            result[parts[0]] = parts[1]
    return result


def load_handles(store: Path) -> dict[str, dict]:
    """Read builds/<build_key> -> {"object_hash":..., "inputs":[...]}."""
    handles: dict[str, dict] = {}
    builds = store / "builds"
    if not builds.is_dir():
        return handles
    for entry in builds.iterdir():
        if not entry.is_file():
            continue
        try:
            data = json.loads(entry.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        handles[entry.name] = {
            "object_hash": data.get("object_hash"),
            "inputs": data.get("inputs", []),
        }
    return handles


def load_oh_to_name(store: Path) -> dict[str, str]:
    """object_hash -> recipe name, from object-refs/<name> symlinks.

    Each ref is a symlink to ``../objects/<object_hash>``, so the object hash
    is the basename of the link target. (The old object-record-refs/ dir was
    removed from the store layout in mbuild c8ad6d6.)
    """
    mapping: dict[str, str] = {}
    refs = store / "object-refs"
    if not refs.is_dir():
        return mapping
    for entry in refs.iterdir():
        try:
            target = os.readlink(entry)
        except OSError:
            continue
        oh = os.path.basename(target.rstrip("/"))
        if oh:
            # First writer wins; names are effectively unique per object here.
            mapping.setdefault(oh, entry.name)
    return mapping


def load_name_to_tag(store: Path) -> dict[str, str]:
    """name -> tag from request.json (.nodes is keyed by nN). Optional."""
    mapping: dict[str, str] = {}
    path = store / "request.json"
    if not path.is_file():
        return mapping
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return mapping
    nodes = data.get("nodes", {})
    values = nodes.values() if isinstance(nodes, dict) else nodes
    for node in values:
        if isinstance(node, dict) and node.get("name"):
            mapping[node["name"]] = node.get("tag", "?")
    return mapping


def _sha256_file(path: Path) -> str:
    """Hex SHA-256 of a file's contents."""
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def _manifest_from_directory(root: Path) -> dict[str, tuple]:
    """path -> signature tuple, walking a plain-object directory on disk.

    Symlinks are never followed (checked first), so directory-symlink loops are
    impossible. Signatures mirror the manifest ones enough for diffing: files
    carry their content hash, symlinks their target.
    """
    entries: dict[str, tuple] = {}

    def walk(directory: str, prefix: str) -> None:
        with os.scandir(directory) as it:
            for entry in it:
                rel = prefix + entry.name
                if entry.is_symlink():
                    entries[rel] = ("l", os.readlink(entry.path))
                elif entry.is_dir(follow_symlinks=False):
                    entries[rel] = ("d",)
                    walk(entry.path, rel + "/")
                elif entry.is_file(follow_symlinks=False):
                    entries[rel] = ("f", _sha256_file(Path(entry.path)))
                else:
                    entries[rel] = ("?",)

    walk(str(root), "")
    return entries


def load_manifest(store: Path, object_hash: str) -> dict[str, tuple] | None:
    """path -> signature tuple, for every entry in the object.

    Returns None if the object is missing.

    An object is stored under ``objects/<object_hash>`` in one of two forms:

    * an fs-tree manifest -- a newline-delimited JSON *file*. The first line is a
      schema header (``{"schema":"bobr-fs-tree-manifest"}``); each subsequent
      line is one entry keyed by ``p`` (path relative to the tree root, "" is the
      root). The fields carried depend on the entry type ``t``:
        - "f" file:    ``h`` (content hash)
        - "d" dir:     ``u``/``g``/``m`` (uid/gid/mode)
        - "l" symlink: ``u``/``g``/``x`` (x = link target)
      The signature captures every field except ``p`` (the key), so any change in
      content, mode, ownership or link target counts as a difference.

    * a plain-object *directory* holding real files (reports, EROFS images, ...).
      It is walked directly; signatures carry file content hashes / link targets.
    """
    path = store / "objects" / object_hash
    if path.is_dir():
        return _manifest_from_directory(path)
    if not path.is_file():
        return None
    entries: dict[str, tuple] = {}
    with path.open() as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                e = json.loads(line)
            except json.JSONDecodeError:
                continue
            if "p" not in e:
                # schema header (or any non-entry line)
                continue
            p = e["p"]
            # Signature = every field that contributes to identity, i.e. the
            # whole entry minus its path key.
            entries[p] = tuple(sorted(
                (k, v) for k, v in e.items() if k != "p"
            ))
    return entries


# -----------------------------------------------------------------------------
# resolving names
# -----------------------------------------------------------------------------

class Resolver:
    """Best-effort build_key -> (name, tag), using whichever store knows it."""

    def __init__(self, stores: list["StoreView"]):
        self.stores = stores

    def name(self, build_key: str) -> str:
        for sv in self.stores:
            handle = sv.handles.get(build_key)
            if handle and handle["object_hash"] in sv.oh_to_name:
                return sv.oh_to_name[handle["object_hash"]]
        return f"(unnamed {build_key[:12]})"

    def tag(self, name: str) -> str:
        for sv in self.stores:
            if name in sv.name_to_tag:
                return sv.name_to_tag[name]
        return "?"


class StoreView:
    def __init__(self, path: Path):
        self.path = path
        self.label = path.name
        self.hashes = load_hashes(path)
        self.handles = load_handles(path)
        self.oh_to_name = load_oh_to_name(path)
        self.name_to_tag = load_name_to_tag(path)


# -----------------------------------------------------------------------------
# reporting helpers
# -----------------------------------------------------------------------------

def section(title: str) -> None:
    print()
    print(f"== {title} ==")


def compare_hashes(a: StoreView, b: StoreView) -> None:
    section("hashes.txt")
    keys = sorted(set(a.hashes) | set(b.hashes))
    if not keys:
        print("  (no hashes.txt in either store)")
        return
    all_match = True
    for key in keys:
        va, vb = a.hashes.get(key), b.hashes.get(key)
        if va == vb:
            print(f"  ok    {key}: {va}")
        else:
            all_match = False
            print(f"  DIFF  {key}: A={va or '<missing>'}  B={vb or '<missing>'}")
    if not all_match:
        print("  NOTE: commits differ -- continuing anyway.")


def compare_build_keys(a: StoreView, b: StoreView) -> set[str]:
    section("build keys")
    ka, kb = set(a.handles), set(b.handles)
    common = ka & kb
    only_a, only_b = ka - kb, kb - ka
    print(f"  A: {len(ka)}   B: {len(kb)}   common: {len(common)}")
    resolver = Resolver([a, b])
    for label, keys, owner in (("only in A", only_a, a), ("only in B", only_b, b)):
        if keys:
            print(f"  {label}: {len(keys)}")
            for bk in sorted(keys, key=lambda k: resolver.name(k)):
                print(f"      {resolver.name(bk):40s} {bk[:12]}")
    if not only_a and not only_b:
        print("  build-key sets are identical.")
    return common


def diff_files(a: StoreView, b: StoreView, oh_a: str, oh_b: str,
               max_files: int) -> None:
    ma = load_manifest(a.path, oh_a)
    mb = load_manifest(b.path, oh_b)
    if ma is None or mb is None:
        missing = a.label if ma is None else b.label
        print(f"        (manifest unavailable in {missing}; skipping file diff)")
        return
    paths_a, paths_b = set(ma), set(mb)
    only_a = sorted(paths_a - paths_b)
    only_b = sorted(paths_b - paths_a)
    changed = sorted(p for p in (paths_a & paths_b) if ma[p] != mb[p])
    total = len(only_a) + len(only_b) + len(changed)
    print(f"        differing entries: {total} "
          f"(changed={len(changed)}, only-A={len(only_a)}, only-B={len(only_b)})")
    shown = 0
    for tag, items in (("changed", changed), ("only-A", only_a), ("only-B", only_b)):
        for p in items:
            if shown >= max_files:
                print(f"        ... ({total - shown} more)")
                return
            print(f"        [{tag}] {p or '/'}")
            shown += 1


def compare_objects(a: StoreView, b: StoreView, common: set[str],
                    show_files: bool, max_files: int,
                    show_inherited: bool) -> int:
    section("object hashes (common build keys)")
    resolver = Resolver([a, b])
    roots, inherited = [], []
    for bk in common:
        ha, hb = a.handles[bk], b.handles[bk]
        if ha["object_hash"] == hb["object_hash"]:
            continue
        same_inputs = sorted(ha["inputs"]) == sorted(hb["inputs"])
        (roots if same_inputs else inherited).append(bk)

    total = len(roots) + len(inherited)
    if total == 0:
        print(f"  no divergences: all {len(common)} common build keys match.")
        return 0

    print(f"  divergent: {total} of {len(common)}  "
          f"(roots={len(roots)}, inherited={len(inherited)})")

    def describe(bk: str) -> tuple[str, str]:
        name = resolver.name(bk)
        return name, resolver.tag(name)

    section(f"ROOT divergences ({len(roots)})  [same inputs, different output]")
    if not roots:
        print("  none -- every divergence is inherited from upstream.")
    for bk in sorted(roots, key=lambda k: describe(k)[0]):
        name, tag = describe(bk)
        print(f"  * {name}  [{tag}]")
        print(f"      build_key: {bk}")
        print(f"      A: {a.handles[bk]['object_hash']}")
        print(f"      B: {b.handles[bk]['object_hash']}")
        if show_files:
            diff_files(a, b, a.handles[bk]["object_hash"],
                       b.handles[bk]["object_hash"], max_files)

    if show_inherited and inherited:
        section(f"inherited divergences ({len(inherited)})")
        for bk in sorted(inherited, key=lambda k: describe(k)[0]):
            name, tag = describe(bk)
            print(f"  - {name:40s} [{tag}]")
    elif inherited:
        section(f"inherited divergences ({len(inherited)})  "
                "[use --inherited to list]")
        names = sorted(describe(bk)[0] for bk in inherited)
        print("  " + ", ".join(names))

    return 1


# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare two mbuild stores for reproducibility.")
    parser.add_argument("store_a", type=Path)
    parser.add_argument("store_b", type=Path)
    parser.add_argument("--no-files", action="store_true",
                        help="do not list differing files for root divergences")
    parser.add_argument("--max-files", type=int, default=40,
                        help="max differing files to print per root (default 40)")
    parser.add_argument("--inherited", action="store_true",
                        help="list inherited divergences one per line")
    args = parser.parse_args()

    for store in (args.store_a, args.store_b):
        if not (store / "builds").is_dir():
            print(f"warning: {store} has no builds/ dir -- is it a store?",
                  file=sys.stderr)

    a = StoreView(args.store_a)
    b = StoreView(args.store_b)

    print(f"A = {a.path}")
    print(f"B = {b.path}")

    compare_hashes(a, b)
    common = compare_build_keys(a, b)
    rc = compare_objects(a, b, common,
                         show_files=not args.no_files,
                         max_files=args.max_files,
                         show_inherited=args.inherited)

    section("summary")
    print(f"  exit {rc}: "
          + ("stores reproduce identically on common build keys."
             if rc == 0 else "object-hash divergences found (see above)."))
    return rc


if __name__ == "__main__":
    sys.exit(main())
