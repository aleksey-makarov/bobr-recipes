#!/usr/bin/env python3
"""Catch reproducibility issues: find builds that produced different output from
the same inputs across two stores.

Compare two bobr stores.

Usage:
    bobr-compare-stores.py STORE_A STORE_B [options]

What it does (never aborts on a mismatch -- it reports and continues):
  1. Compares the Bobr and bobr-recipes identities recorded by each build run.
  2. Compares the set of Build Keys (builds/<key>); reports keys present in
     only one store.
  3. On the build keys present in BOTH, compares the produced object hash.
     A divergence is classified as:
       - ROOT     : the build's inputs (input object hashes) are identical in
                    both stores, yet the output differs -> the build step
                    itself is non-deterministic here.
       - inherited: the inputs already differ -> divergence comes from upstream.
       - unknown  : at least one object record is not valid provenance for the
                    mapping, so the two cases cannot be distinguished safely.
     Root divergences are the actionable ones and are reported in detail,
     including which files inside the object differ.

Exit code: 0 if no object-hash divergences or unreadable mappings are found
among common build keys, else 1.

Store layout used:
  logs/<run-id>/context.json      Bobr build info / recipes provenance
  logs/<run-id>/recipe-catalog.json
                                  recipe names and builder tags
  builds/<build_key>              symlink -> ../objects/<object_hash>
  object-records/<object_hash>.json
                                  optional build provenance used to classify
                                  output divergences
  object-refs/<name>              symlink -> ../objects/<object_hash>
  objects/<obj_hash>              either an fs-tree manifest (newline-delimited
                                  JSON file: schema header then one entry per
                                  line keyed by "p"; t=f/d/l, h/m/u/g/x by type)
                                  or a plain-object directory of real files
                                  (reports, EROFS images, ...)
  hashes.txt (legacy fallback)    old Bobr / recipes build identities
  request.json (legacy fallback)  {"nodes": {"n1": {"name","tag",...}, ...}}
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


# A store is often reached over sshfs, where every open costs a network
# round trip -- measured at 104 ms against one remote store versus 3 ms
# against a local mount. Reading 1803 build mappings one after another put
# three minutes of waiting in front of a comparison that needs one second of
# CPU. The work is pure I/O, so threads overlap it even under the GIL; the
# number is a latency-hiding factor, not a parallelism one.
DEFAULT_READERS = 48
HEX64 = re.compile(r"[0-9a-f]{64}")
OBJECT_TARGET = re.compile(r"\.\./objects/([0-9a-f]{64})")
RUN_CONTEXT_SCHEMA = "bobr-run-context-v1"
RECIPE_CATALOG_SCHEMA = "bobr-recipe-catalog-v1"


def _read_many(paths, read_one, readers: int):
    """Applies `read_one` to every path at once, keeping the input order."""
    if not paths:
        return []
    if readers <= 1 or len(paths) == 1:
        return [read_one(path) for path in paths]
    with ThreadPoolExecutor(max_workers=min(readers, len(paths))) as pool:
        return list(pool.map(read_one, paths))


# -----------------------------------------------------------------------------
# loading
# -----------------------------------------------------------------------------

def load_hashes(store: Path) -> dict[str, str]:
    """Parse the legacy hashes.txt into {component: build identity}."""
    path = store / "hashes.txt"
    result: dict[str, str] = {}
    if not path.is_file():
        return result
    for line in path.read_text().splitlines():
        parts = line.split()
        if len(parts) >= 2:
            result[parts[0]] = parts[1]
    return result


def _canonical_json(value) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def _load_optional_json(path: Path):
    try:
        return json.loads(path.read_text()), None
    except FileNotFoundError:
        return None, None
    except OSError as error:
        return None, f"cannot read {path}: {error}"
    except json.JSONDecodeError as error:
        return None, f"invalid JSON in {path}: {error}"


def _run_files(store: Path, filename: str) -> list[Path]:
    logs = store / "logs"
    if not logs.is_dir():
        return []
    try:
        with os.scandir(logs) as entries:
            return sorted(
                Path(entry.path) / filename
                for entry in entries
                if entry.is_dir(follow_symlinks=False)
            )
    except OSError:
        return []


def load_build_contexts(store: Path, readers: int):
    """Loads distinct run identities, outcomes, and non-fatal diagnostics.

    A store can be filled by several Bobr and recipes revisions, so the result
    is a set per component rather than one alleged store-wide identity. The old
    hashes.txt is consulted only when no modern run context is available.
    """
    identities: dict[str, set[str]] = {
        "bobr": set(),
        "bobr-recipes": set(),
    }
    outcomes: dict[str, int] = {}
    warnings: list[str] = []
    valid_contexts = 0
    paths = _run_files(store, "context.json")
    for path, result in zip(
        paths,
        _read_many(paths, _load_optional_json, readers),
    ):
        context, error = result
        if error is not None:
            warnings.append(error)
            continue
        if context is None:
            continue
        if not isinstance(context, dict) \
                or context.get("schema") != RUN_CONTEXT_SCHEMA:
            warnings.append(f"invalid run context schema in {path}")
            continue
        valid_contexts += 1
        outcome = context.get("outcome")
        if outcome in {"running", "success", "failed"}:
            outcomes[outcome] = outcomes.get(outcome, 0) + 1
        else:
            warnings.append(f"invalid run outcome in {path}")

        bobr = context.get("bobr")
        if isinstance(bobr, dict):
            identities["bobr"].add(_canonical_json(bobr))
        else:
            warnings.append(f"invalid Bobr build information in {path}")

        recipes = context.get("recipes")
        if recipes is None:
            identities["bobr-recipes"].add("unknown")
        elif isinstance(recipes, dict) \
                and isinstance(recipes.get("git_commit"), str) \
                and isinstance(recipes.get("git_dirty"), bool):
            identity = recipes["git_commit"]
            if recipes["git_dirty"]:
                identity += "-dirty"
            identities["bobr-recipes"].add(identity)
        else:
            warnings.append(f"invalid recipes provenance in {path}")

    source = "run logs"
    if valid_contexts == 0:
        legacy = load_hashes(store)
        if legacy:
            source = "legacy hashes.txt"
            for component, identity in legacy.items():
                identities.setdefault(component, set()).add(identity)
        else:
            source = "unavailable"
            logs = store / "logs"
            if logs.is_dir():
                warnings.append(f"no run contexts found under {logs}")
            else:
                warnings.append(f"run logs directory is unavailable: {logs}")
    return identities, outcomes, warnings, source


def load_build_keys(store: Path) -> set[str]:
    """The build keys a store holds, from one directory listing.

    Names alone answer which keys the stores share and which are unique to
    one, and a listing is a single round trip -- the contents behind them are
    only worth fetching for the keys both stores have.
    """
    builds = store / "builds"
    if not builds.is_dir():
        return set()
    try:
        with os.scandir(builds) as it:
            # Do not use is_file(): it follows the symlink, so mappings to
            # directory objects would disappear from the comparison.
            return {entry.name for entry in it}
    except OSError:
        return set()


def load_mappings(
    store: Path,
    keys,
    readers: int,
) -> tuple[dict[str, dict], dict[str, str]]:
    """Read build mappings and optional matching object records.

    ``object_hash`` comes only from the canonical mapping symlink. ``inputs``
    is populated only when the object record names both this hash and this
    build key. Object records describe the first writer of an object, so a
    neutral or shared record is not valid provenance for every mapping that
    happens to reach the same object.
    """
    builds = store / "builds"
    records = store / "object-records"
    ordered = sorted(keys)

    def read_one(key: str):
        try:
            target = os.readlink(builds / key)
        except OSError as error:
            return None, f"cannot read mapping symlink: {error}"
        match = OBJECT_TARGET.fullmatch(target)
        if match is None:
            return None, f"non-canonical mapping target {target!r}"

        object_hash = match.group(1)
        mapping = {
            "object_hash": object_hash,
            "inputs": None,
            "provenance_error": None,
        }
        record_path = records / f"{object_hash}.json"
        try:
            record = json.loads(record_path.read_text())
        except OSError as error:
            mapping["provenance_error"] = f"cannot read object record: {error}"
            return mapping, None
        except json.JSONDecodeError as error:
            mapping["provenance_error"] = f"invalid object record JSON: {error}"
            return mapping, None

        if not isinstance(record, dict):
            mapping["provenance_error"] = "object record is not a JSON object"
        elif record.get("schema") != "bobr-object-record-v4":
            mapping["provenance_error"] = "object record has an unknown schema"
        elif record.get("object_hash") != object_hash:
            mapping["provenance_error"] = "object record names a different object hash"
        elif record.get("build_key") != key:
            mapping["provenance_error"] = (
                "object record belongs to a different build key"
            )
        else:
            inputs = record.get("inputs")
            if not isinstance(inputs, list) or not all(
                isinstance(value, str) and HEX64.fullmatch(value)
                for value in inputs
            ):
                mapping["provenance_error"] = "object record has invalid inputs"
            else:
                mapping["inputs"] = inputs
        return mapping, None

    mappings: dict[str, dict] = {}
    errors: dict[str, str] = {}
    for key, result in zip(ordered, _read_many(ordered, read_one, readers)):
        mapping, error = result
        if mapping is not None:
            mappings[key] = mapping
        if error is not None:
            errors[key] = error
    return mappings, errors


def load_oh_to_name(store: Path, readers: int) -> dict[str, str]:
    """object_hash -> recipe name, from object-refs/<name> symlinks.

    Each ref is a symlink to ``../objects/<object_hash>``, so the object hash
    is the basename of the link target. (The old object-record-refs/ dir was
    removed from the store layout in mbuild c8ad6d6.)
    """
    mapping: dict[str, str] = {}
    refs = store / "object-refs"
    if not refs.is_dir():
        return mapping
    try:
        with os.scandir(refs) as it:
            names = sorted(entry.name for entry in it)
    except OSError:
        return mapping

    def read_one(name: str):
        try:
            return os.readlink(refs / name)
        except OSError:
            return None

    for name, target in zip(names, _read_many(names, read_one, readers)):
        if target is None:
            continue
        oh = os.path.basename(target.rstrip("/"))
        if oh:
            # Several refs can point at one object -- a name and its dated
            # generations (`initrd`, `initrd.260804183238`), or two targets
            # built from the same inputs. Reading in sorted order makes the
            # winner the lexicographically first, which is the plain name: a
            # generation only ever adds a suffix. The old readdir order picked
            # whichever the filesystem happened to hand over first.
            mapping.setdefault(oh, name)
    return mapping


def _merge_name_tags(mapping: dict[str, set[str]], data) -> bool:
    """Merges one catalog/request nodes object, returning whether it was valid."""
    if not isinstance(data, dict):
        return False
    nodes = data.get("nodes", {})
    if isinstance(nodes, dict):
        values = nodes.values()
    elif isinstance(nodes, list):
        values = nodes
    else:
        return False
    for node in values:
        if not isinstance(node, dict):
            continue
        name, tag = node.get("name"), node.get("tag")
        if isinstance(name, str) and isinstance(tag, str):
            mapping.setdefault(name, set()).add(tag)
    return True


def load_name_to_tags(store: Path, readers: int):
    """Loads name -> possible tags from run catalogs or legacy request.json."""
    mapping: dict[str, set[str]] = {}
    warnings: list[str] = []
    valid_catalogs = 0
    paths = _run_files(store, "recipe-catalog.json")
    for path, result in zip(
        paths,
        _read_many(paths, _load_optional_json, readers),
    ):
        catalog, error = result
        if error is not None:
            warnings.append(error)
            continue
        if catalog is None:
            continue
        if not isinstance(catalog, dict) \
                or catalog.get("schema") != RECIPE_CATALOG_SCHEMA \
                or not _merge_name_tags(mapping, catalog):
            warnings.append(f"invalid recipe catalog in {path}")
            continue
        valid_catalogs += 1

    if valid_catalogs != 0:
        return mapping, warnings

    # A few old stores retained one complete lowered request at their root.
    path = store / "request.json"
    if not path.is_file():
        if _run_files(store, "context.json"):
            warnings.append(f"no recipe catalogs found under {store / 'logs'}")
        return mapping, warnings
    data, error = _load_optional_json(path)
    if error is not None:
        warnings.append(error)
    elif not _merge_name_tags(mapping, data):
        warnings.append(f"invalid legacy request in {path}")
    return mapping, warnings


def _sha256_file(path: Path) -> str:
    """Hex SHA-256 of a file's contents."""
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def _manifest_from_directory(root: Path, readers: int) -> dict[str, tuple]:
    """path -> signature tuple, walking a plain-object directory on disk.

    Symlinks are never followed (checked first), so directory-symlink loops are
    impossible. Signatures mirror the manifest ones enough for diffing: files
    carry their content hash, symlinks their target.
    """
    entries: dict[str, tuple] = {}
    # Hashing reads every byte of every file, which is the slow part on a
    # remote store; the walk only lists directories. Collect first, hash after,
    # so the reads overlap.
    to_hash: list[tuple[str, str]] = []

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
                    to_hash.append((rel, entry.path))
                else:
                    entries[rel] = ("?",)

    walk(str(root), "")
    digests = _read_many(
        [path for _, path in to_hash],
        lambda path: _sha256_file(Path(path)),
        readers,
    )
    for (rel, _), digest in zip(to_hash, digests):
        entries[rel] = ("f", digest)
    return entries


def load_manifest(store: Path, object_hash: str, readers: int) -> dict[str, tuple] | None:
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
        return _manifest_from_directory(path, readers)
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
            mapping = sv.mappings.get(build_key)
            if mapping and mapping["object_hash"] in sv.oh_to_name:
                return sv.oh_to_name[mapping["object_hash"]]
        return f"(unnamed {build_key[:12]})"

    def tag(self, name: str) -> str:
        tags: set[str] = set()
        for sv in self.stores:
            tags.update(sv.name_to_tags.get(name, set()))
        if not tags:
            return "?"
        if len(tags) == 1:
            return next(iter(tags))
        return "ambiguous: " + ", ".join(sorted(tags))


class StoreView:
    """One store, read as late as possible.

    Only run contexts and the set of build keys are read up front. Handles follow
    once both stores are known, for the keys they share. The name and tag maps
    exist solely to label divergences in the report, so a run that finds none
    never pays for the thousand-odd readlinks behind them.
    """

    def __init__(self, path: Path, readers: int):
        self.path = path
        self.label = path.name
        self.readers = readers
        (
            self.build_contexts,
            self.run_outcomes,
            self.metadata_warnings,
            self.context_source,
        ) = load_build_contexts(path, readers)
        self.build_keys = load_build_keys(path)
        self.mappings: dict[str, dict] = {}
        self.mapping_errors: dict[str, str] = {}
        self._oh_to_name: dict[str, str] | None = None
        self._name_to_tags: dict[str, set[str]] | None = None

    def read_mappings(self, keys) -> None:
        self.mappings, self.mapping_errors = load_mappings(
            self.path, keys, self.readers)

    @property
    def oh_to_name(self) -> dict[str, str]:
        if self._oh_to_name is None:
            self._oh_to_name = load_oh_to_name(self.path, self.readers)
        return self._oh_to_name

    @property
    def name_to_tags(self) -> dict[str, set[str]]:
        if self._name_to_tags is None:
            self._name_to_tags, warnings = load_name_to_tags(
                self.path, self.readers
            )
            self.metadata_warnings.extend(warnings)
        return self._name_to_tags


# -----------------------------------------------------------------------------
# reporting helpers
# -----------------------------------------------------------------------------

def section(title: str) -> None:
    print()
    print(f"== {title} ==")


def _format_identity_set(values: set[str]) -> str:
    if not values:
        return "<unavailable>"
    return ", ".join(sorted(values))


def compare_build_contexts(a: StoreView, b: StoreView) -> None:
    section("build contexts")
    print(f"  A: {a.context_source}")
    print(f"  B: {b.context_source}")
    keys = sorted(set(a.build_contexts) | set(b.build_contexts))
    if not keys:
        print("  (no build identities in either store)")
        return
    if a.run_outcomes:
        print("  A outcomes: " + ", ".join(
            f"{name}={count}" for name, count in sorted(a.run_outcomes.items())
        ))
    if b.run_outcomes:
        print("  B outcomes: " + ", ".join(
            f"{name}={count}" for name, count in sorted(b.run_outcomes.items())
        ))
    for key in keys:
        va = a.build_contexts.get(key, set())
        vb = b.build_contexts.get(key, set())
        if va == vb:
            print(f"  ok    {key}: {_format_identity_set(va)}")
        else:
            print(f"  DIFF  {key}:")
            print(f"          A={_format_identity_set(va)}")
            print(f"          B={_format_identity_set(vb)}")
    if any(a.build_contexts.get(key, set()) != b.build_contexts.get(key, set())
           for key in keys):
        print("  NOTE: recorded build contexts differ -- continuing anyway.")


def compare_build_keys(a: StoreView, b: StoreView) -> set[str]:
    section("build keys")
    ka, kb = a.build_keys, b.build_keys
    common = ka & kb
    only_a, only_b = ka - kb, kb - ka
    print(f"  A: {len(ka)}   B: {len(kb)}   common: {len(common)}")
    resolver = Resolver([a, b])
    for label, keys, owner in (("only in A", only_a, a), ("only in B", only_b, b)):
        if keys:
            print(f"  {label}: {len(keys)}")
            for bk in sorted(keys, key=lambda k: resolver.name(k)):
                print(f"      {resolver.name(bk):40s} {bk[:12]}")
                if bk in owner.mapping_errors:
                    print(f"          invalid mapping: {owner.mapping_errors[bk]}")
    if not only_a and not only_b:
        print("  build-key sets are identical.")
    return common


def diff_files(a: StoreView, b: StoreView, oh_a: str, oh_b: str,
               max_files: int) -> None:
    # Two independent trees on two different stores: no reason to wait for one
    # before starting the other.
    ma, mb = _read_many(
        [(a, oh_a), (b, oh_b)],
        lambda pair: load_manifest(pair[0].path, pair[1], pair[0].readers),
        2,
    )
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
    roots, inherited, unknown = [], [], []
    unreadable = []
    for bk in common:
        if bk not in a.mappings or bk not in b.mappings:
            unreadable.append(bk)
            continue
        ha, hb = a.mappings[bk], b.mappings[bk]
        if ha["object_hash"] == hb["object_hash"]:
            continue
        if ha["inputs"] is None or hb["inputs"] is None:
            unknown.append(bk)
        elif ha["inputs"] == hb["inputs"]:
            roots.append(bk)
        else:
            inherited.append(bk)

    total = len(roots) + len(inherited) + len(unknown)
    if total == 0 and not unreadable:
        print(f"  no divergences: all {len(common)} common build keys match.")
        return 0

    print(f"  divergent: {total} of {len(common)}  "
          f"(roots={len(roots)}, inherited={len(inherited)}, "
          f"unknown={len(unknown)})")
    if unreadable:
        print(f"  unreadable mappings: {len(unreadable)}")

    def describe(bk: str) -> tuple[str, str]:
        name = resolver.name(bk)
        return name, resolver.tag(name)

    section(f"ROOT divergences ({len(roots)})  [same inputs, different output]")
    if not roots:
        print("  none.")
    for bk in sorted(roots, key=lambda k: describe(k)[0]):
        name, tag = describe(bk)
        print(f"  * {name}  [{tag}]")
        print(f"      build_key: {bk}")
        print(f"      A: {a.mappings[bk]['object_hash']}")
        print(f"      B: {b.mappings[bk]['object_hash']}")
        if show_files:
            diff_files(a, b, a.mappings[bk]["object_hash"],
                       b.mappings[bk]["object_hash"], max_files)

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

    if unknown:
        section(f"unknown-provenance divergences ({len(unknown)})")
        for bk in sorted(unknown, key=lambda k: describe(k)[0]):
            name, tag = describe(bk)
            print(f"  ? {name}  [{tag}]")
            print(f"      build_key: {bk}")
            print(f"      A: {a.mappings[bk]['object_hash']}")
            print("         " + (a.mappings[bk]["provenance_error"]
                                  or "matching object record"))
            print(f"      B: {b.mappings[bk]['object_hash']}")
            print("         " + (b.mappings[bk]["provenance_error"]
                                  or "matching object record"))
            if show_files:
                diff_files(a, b, a.mappings[bk]["object_hash"],
                           b.mappings[bk]["object_hash"], max_files)

    if unreadable:
        section(f"unreadable build mappings ({len(unreadable)})")
        for bk in sorted(unreadable):
            print(f"  ! {bk}")
            if bk in a.mapping_errors:
                print(f"      A: {a.mapping_errors[bk]}")
            if bk in b.mapping_errors:
                print(f"      B: {b.mapping_errors[bk]}")

    return 1


# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare two bobr stores for reproducibility.")
    parser.add_argument("store_a", type=Path)
    parser.add_argument("store_b", type=Path)
    parser.add_argument("--no-files", action="store_true",
                        help="do not list differing files for root divergences")
    parser.add_argument("--max-files", type=int, default=40,
                        help="max differing files to print per root (default 40)")
    parser.add_argument("--inherited", action="store_true",
                        help="list inherited divergences one per line")
    parser.add_argument("--readers", type=int, default=DEFAULT_READERS,
                        help=f"reads to keep in flight per store "
                             f"(default {DEFAULT_READERS}; 1 disables threading)")
    args = parser.parse_args()

    for store in (args.store_a, args.store_b):
        if not (store / "builds").is_dir():
            print(f"warning: {store} has no builds/ dir -- is it a store?",
                  file=sys.stderr)

    readers = max(1, args.readers)
    a = StoreView(args.store_a, readers)
    b = StoreView(args.store_b, readers)

    print(f"A = {a.path}")
    print(f"B = {b.path}")

    compare_build_contexts(a, b)
    # Every key of each store is read: the ones they share carry the comparison,
    # and the ones they do not are still named in the report.
    a.read_mappings(a.build_keys)
    b.read_mappings(b.build_keys)
    common = compare_build_keys(a, b)
    rc = compare_objects(a, b, common,
                         show_files=not args.no_files,
                         max_files=args.max_files,
                         show_inherited=args.inherited)

    warnings = [("A", warning) for warning in a.metadata_warnings]
    warnings += [("B", warning) for warning in b.metadata_warnings]
    if warnings:
        section("metadata warnings")
        for label, warning in warnings:
            print(f"  {label}: {warning}")

    section("summary")
    print(f"  exit {rc}: "
          + ("stores reproduce identically on common build keys."
             if rc == 0 else "object-hash divergences found (see above)."))
    return rc


if __name__ == "__main__":
    sys.exit(main())
