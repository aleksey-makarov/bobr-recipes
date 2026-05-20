#!/usr/bin/env python3

import argparse
import fnmatch
import os
import pathlib
import shutil
import stat
import sys


def fail(message: str) -> None:
    print(f"tree-subset: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_pattern(pattern: str) -> str:
    if pattern == "" or pattern.startswith("/"):
        fail(f"invalid include pattern: {pattern!r}")
    parts = pathlib.PurePosixPath(pattern).parts
    if any(part == ".." for part in parts):
        fail(f"include pattern must not contain '..': {pattern!r}")
    return pattern


def load_include_patterns(config_dir: pathlib.Path) -> list[str]:
    include_dir = config_dir / "include"
    if not include_dir.is_dir():
        fail(f"missing include config directory: {include_dir}")

    patterns = [
        validate_pattern(path.read_text(encoding="utf-8"))
        for path in sorted(include_dir.iterdir())
        if path.is_file()
    ]
    if not patterns:
        fail("include must contain at least one pattern")
    return patterns


def scan_tree(input_root: pathlib.Path) -> dict[str, dict]:
    if not input_root.is_dir():
        fail(f"input tree is not a directory: {input_root}")

    entries: dict[str, dict] = {"": {"t": "d", "m": stat.S_IMODE(input_root.lstat().st_mode)}}
    for current_root, dirnames, filenames in os.walk(input_root, followlinks=False):
        current = pathlib.Path(current_root)
        rel_dir = current.relative_to(input_root).as_posix()
        if rel_dir == ".":
            rel_dir = ""

        dirnames.sort()
        filenames.sort()

        for name in dirnames + filenames:
            path = current / name
            rel = path.relative_to(input_root).as_posix()
            st = path.lstat()
            mode = stat.S_IMODE(st.st_mode)
            if path.is_symlink():
                entries[rel] = {"t": "l", "x": os.readlink(path)}
            elif path.is_dir():
                entries[rel] = {"t": "d", "m": mode}
            elif path.is_file():
                entries[rel] = {"t": "f", "m": mode}
            else:
                fail(f"unsupported filesystem entry: {rel}")

    return entries


def path_matches(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def add_parent_dirs(path: str, entries: dict[str, dict], selected: set[str]) -> None:
    parent = pathlib.PurePosixPath(path).parent
    while str(parent) not in {"", "."}:
        parent_path = parent.as_posix()
        if parent_path in entries:
            selected.add(parent_path)
        parent = parent.parent
    if "" in entries:
        selected.add("")


def select_paths(entries: dict[str, dict], patterns: list[str]) -> set[str]:
    selected: set[str] = set()
    matched_patterns = {pattern: False for pattern in patterns}

    for path, entry in entries.items():
        if path == "":
            continue
        for pattern in patterns:
            if path_matches(path, [pattern]):
                matched_patterns[pattern] = True
                selected.add(path)
                add_parent_dirs(path, entries, selected)
                break

    missing_patterns = [pattern for pattern, matched in matched_patterns.items() if not matched]
    if missing_patterns:
        fail("include pattern matched no paths: " + ", ".join(missing_patterns))
    return selected


def mkdir_with_mode(path: pathlib.Path, mode: int) -> None:
    path.mkdir(parents=True, exist_ok=True)
    path.chmod(mode)


def copy_file(src: pathlib.Path, dst: pathlib.Path, mode: int) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst, follow_symlinks=False)
    dst.chmod(mode)


def copy_symlink(dst: pathlib.Path, target: str) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() or dst.is_symlink():
        dst.unlink()
    os.symlink(target, dst)


def materialize_subset(input_root: pathlib.Path, output_dir: pathlib.Path, entries: dict[str, dict], selected: set[str]) -> None:
    directories = sorted(path for path in selected if entries[path]["t"] == "d")
    leaves = sorted(path for path in selected if entries[path]["t"] != "d")

    for path in directories:
        if path == "":
            continue
        entry = entries[path]
        mkdir_with_mode(output_dir / path, int(entry.get("m", 0o755)))

    for path in leaves:
        entry = entries[path]
        kind = entry["t"]
        if kind == "f":
            copy_file(input_root / path, output_dir / path, int(entry.get("m", 0o644)))
        elif kind == "l":
            target = entry.get("x")
            if not isinstance(target, str):
                fail(f"manifest symlink entry has no string target: {path}")
            copy_symlink(output_dir / path, target)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="input tree root directory")
    parser.add_argument("--output", required=True, help="output directory")
    parser.add_argument("--config", required=True, help="materialized script_config directory")
    args = parser.parse_args()

    input_root = pathlib.Path(args.input)
    output_dir = pathlib.Path(args.output)
    config_dir = pathlib.Path(args.config)

    patterns = load_include_patterns(config_dir)
    entries = scan_tree(input_root)
    selected = select_paths(entries, patterns)
    materialize_subset(input_root, output_dir, entries, selected)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
