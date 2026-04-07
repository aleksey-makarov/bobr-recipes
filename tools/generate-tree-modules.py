#!/usr/bin/env python3
import argparse
import json
import os
import pathlib
import sys


SKIP_DIRS = {".git", "old", "target"}
PLACEHOLDER_FILES = {".gitkeep"}


def iter_tree_sources(repo_root: pathlib.Path):
    for current_root, dirnames, filenames in os.walk(repo_root):
        dirnames[:] = [
            dirname
            for dirname in dirnames
            if dirname not in SKIP_DIRS and not dirname.startswith(".")
        ]
        current = pathlib.Path(current_root)

        for dirname in dirnames:
            if dirname.endswith("-tree-src"):
                yield current / dirname
        for filename in filenames:
            if filename.endswith("-tree-src"):
                yield current / filename


def is_utf8_text(path: pathlib.Path) -> str:
    data = path.read_bytes()
    if b"\x00" in data:
        raise ValueError(f"binary file is not supported: {path}")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as error:
        raise ValueError(f"non-UTF-8 file is not supported: {path}: {error}") from error


def executable_bit(path: pathlib.Path) -> bool:
    return bool(path.stat().st_mode & 0o111)


def dir_is_effectively_empty(path: pathlib.Path) -> bool:
    return not any(entry.name not in PLACEHOLDER_FILES for entry in path.iterdir())


def emit_entries_from_source(source_path: pathlib.Path):
    if source_path.is_symlink():
        raise ValueError(
            f"single-file symlink tree sources are not supported: {source_path}"
        )

    if source_path.is_file():
        is_utf8_text(source_path)
        return [
            {
                "type": "file",
                "path": source_path.name.removesuffix("-tree-src"),
                "source_path": source_path,
                "executable": executable_bit(source_path),
            }
        ]

    if not source_path.is_dir():
        raise ValueError(f"tree source must be a regular file or directory: {source_path}")

    entries = []
    for current_root, dirnames, filenames in os.walk(source_path):
        current = pathlib.Path(current_root)
        rel_dir = current.relative_to(source_path)

        if rel_dir != pathlib.Path(".") and dir_is_effectively_empty(current):
            entries.append(
                {
                    "type": "dir",
                    "path": rel_dir.as_posix(),
                }
            )

        dirnames.sort()
        filenames = sorted(
            filename for filename in filenames if filename not in PLACEHOLDER_FILES
        )

        symlink_dirs = []
        kept_dirs = []
        for dirname in dirnames:
            path = current / dirname
            if path.is_symlink():
                symlink_dirs.append(
                    {
                        "type": "symlink",
                        "path": path.relative_to(source_path).as_posix(),
                        "target": os.readlink(path),
                    }
                )
            else:
                kept_dirs.append(dirname)
        dirnames[:] = kept_dirs
        entries.extend(symlink_dirs)

        for filename in filenames:
            path = current / filename
            if path.is_symlink():
                entries.append(
                    {
                        "type": "symlink",
                        "path": path.relative_to(source_path).as_posix(),
                        "target": os.readlink(path),
                    }
                )
                continue
            if not path.is_file():
                raise ValueError(f"unsupported filesystem entry in tree source: {path}")
            is_utf8_text(path)
            entries.append(
                {
                    "type": "file",
                    "path": path.relative_to(source_path).as_posix(),
                    "source_path": path,
                    "executable": executable_bit(path),
                }
            )

    if not entries:
        raise ValueError(f"tree source must not be empty: {source_path}")

    entries.sort(key=lambda entry: (entry["path"], entry["type"]))
    return entries


def import_path_for(target_path: pathlib.Path, source_path: pathlib.Path) -> str:
    return pathlib.Path(os.path.relpath(source_path, target_path.parent)).as_posix()


def render_module(entries, target_path: pathlib.Path):
    lines = ["{", "  entries = ["]
    for entry in entries:
        if entry["type"] == "file":
            import_path = import_path_for(target_path, entry["source_path"])
            lines.extend(
                [
                    "    {",
                    '      type = "file",',
                    f'      path = {json.dumps(entry["path"], ensure_ascii=False)},',
                    f"      text = import {json.dumps(import_path, ensure_ascii=False)} as 'Text,",
                    f'      executable = {"true" if entry["executable"] else "false"},',
                    "    },",
                ]
            )
        elif entry["type"] == "dir":
            lines.extend(
                [
                    "    {",
                    '      type = "dir",',
                    f'      path = {json.dumps(entry["path"], ensure_ascii=False)},',
                    "    },",
                ]
            )
        elif entry["type"] == "symlink":
            lines.extend(
                [
                    "    {",
                    '      type = "symlink",',
                    f'      path = {json.dumps(entry["path"], ensure_ascii=False)},',
                    f'      target = {json.dumps(entry["target"], ensure_ascii=False)},',
                    "    },",
                ]
            )
        else:
            raise ValueError(f"unsupported entry type: {entry['type']}")
    lines.extend(["  ],", "}"])
    return "\n".join(lines) + "\n"


def generated_path_for(source_path: pathlib.Path) -> pathlib.Path:
    suffix = source_path.name.removesuffix("-tree-src")
    return source_path.with_name(f"{suffix}-tree.ncl")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=None)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    repo_root = pathlib.Path(args.repo_root or pathlib.Path(__file__).resolve().parent.parent)
    sources = sorted(iter_tree_sources(repo_root))

    for source_path in sources:
        target_path = generated_path_for(source_path)
        rendered = render_module(emit_entries_from_source(source_path), target_path)
        current = target_path.read_text(encoding="utf-8") if target_path.exists() else None

        if args.check:
            if current != rendered:
                print(f"tree module is stale: {target_path}", file=sys.stderr)
                return 1
        else:
            if current != rendered:
                target_path.write_text(rendered, encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
