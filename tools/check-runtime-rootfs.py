#!/usr/bin/env python3

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys


DEFAULT_LIBRARY_DIRS = [
    "/lib",
    "/lib64",
    "/usr/lib",
    "/usr/lib64",
]
PSEUDO_FS_PREFIXES = [
    "/dev",
    "/proc",
    "/sys",
]


def is_under(path: pathlib.Path, root: pathlib.Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def has_elf_magic(path: pathlib.Path) -> bool:
    try:
        with path.open("rb") as handle:
            return handle.read(4) == b"\x7fELF"
    except OSError:
        return False


def run_readelf(readelf: str, flag: str, path: pathlib.Path) -> tuple[int, str]:
    proc = subprocess.run(
        [readelf, flag, str(path)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return proc.returncode, proc.stdout


def parse_program_interpreter(output: str) -> str | None:
    match = re.search(r"\[Requesting program interpreter:\s*([^\]]+)\]", output)
    if match:
        return match.group(1).strip()
    return None


def parse_dynamic_section(output: str) -> tuple[list[str], list[str], list[str], bool]:
    needed: list[str] = []
    rpath: list[str] = []
    runpath: list[str] = []
    saw_dynamic_section = "Dynamic section" in output

    for line in output.splitlines():
        needed_match = re.search(r"\(NEEDED\)\s+Shared library:\s*\[([^\]]+)\]", line)
        if needed_match:
            needed.append(needed_match.group(1))
            continue

        rpath_match = re.search(r"\(RPATH\)\s+Library rpath:\s*\[([^\]]*)\]", line)
        if rpath_match:
            rpath.extend(split_search_path(rpath_match.group(1)))
            continue

        runpath_match = re.search(r"\(RUNPATH\)\s+Library runpath:\s*\[([^\]]*)\]", line)
        if runpath_match:
            runpath.extend(split_search_path(runpath_match.group(1)))

    return needed, rpath, runpath, saw_dynamic_section


def split_search_path(value: str) -> list[str]:
    return [item for item in value.split(":") if item]


def rootfs_path(root: pathlib.Path, path: str) -> pathlib.Path:
    if path.startswith("/"):
        return (root / path.lstrip("/")).resolve(strict=False)
    return (root / path).resolve(strict=False)


def is_allowed_pseudo_target(target: str) -> bool:
    return any(target == prefix or target.startswith(prefix + "/") for prefix in PSEUDO_FS_PREFIXES)


def resolve_symlink_target(root: pathlib.Path, link: pathlib.Path, target: str) -> pathlib.Path | None:
    if os.path.isabs(target):
        if is_allowed_pseudo_target(target):
            return None
        return (root / target.lstrip("/")).resolve(strict=False)
    return (link.parent / target).resolve(strict=False)


def expand_origin(path_entry: str, obj_path: pathlib.Path, root: pathlib.Path) -> pathlib.Path:
    origin = "/" + obj_path.parent.relative_to(root).as_posix()
    expanded = (
        path_entry
        .replace("${ORIGIN}", origin)
        .replace("$ORIGIN", origin)
    )
    return rootfs_path(root, expanded)


def candidate_library_dirs(
    root: pathlib.Path,
    obj_path: pathlib.Path,
    rpath: list[str],
    runpath: list[str],
) -> list[pathlib.Path]:
    configured_paths = runpath if runpath else rpath
    candidates = [expand_origin(entry, obj_path, root) for entry in configured_paths]
    candidates.extend(rootfs_path(root, entry) for entry in DEFAULT_LIBRARY_DIRS)

    deduped: list[pathlib.Path] = []
    seen: set[str] = set()
    for candidate in candidates:
        key = os.path.normpath(str(candidate))
        if key not in seen:
            seen.add(key)
            deduped.append(candidate)
    return deduped


def library_exists(root: pathlib.Path, obj_path: pathlib.Path, name: str, rpath: list[str], runpath: list[str]) -> bool:
    if "/" in name:
        target = rootfs_path(root, name)
        return is_under(target, root) and target.exists()

    for directory in candidate_library_dirs(root, obj_path, rpath, runpath):
        target = (directory / name).resolve(strict=False)
        if is_under(target, root) and target.exists():
            return True
    return False


def iter_symlinks(root: pathlib.Path):
    for current_root, dirnames, filenames in os.walk(root, followlinks=False):
        current = pathlib.Path(current_root)
        for name in sorted(dirnames + filenames):
            path = current / name
            if path.is_symlink():
                yield path


def iter_regular_files(root: pathlib.Path):
    for current_root, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames.sort()
        for filename in sorted(filenames):
            path = pathlib.Path(current_root) / filename
            if path.is_file() and not path.is_symlink():
                yield path


def relative_display(root: pathlib.Path, path: pathlib.Path) -> str:
    return "/" + path.relative_to(root).as_posix()


def check_symlinks(root: pathlib.Path) -> tuple[int, list[str]]:
    checked = 0
    failures: list[str] = []
    for link in iter_symlinks(root):
        checked += 1
        target = os.readlink(link)
        resolved = resolve_symlink_target(root, link, target)
        if resolved is None:
            continue
        if not is_under(resolved, root):
            failures.append(
                f"broken symlink leaves rootfs: {relative_display(root, link)} -> {target}"
            )
            continue
        if not resolved.exists():
            failures.append(
                f"broken symlink: {relative_display(root, link)} -> {target}"
            )
    return checked, failures


def check_elf_files(root: pathlib.Path, readelf: str) -> tuple[int, list[str]]:
    checked = 0
    failures: list[str] = []

    for path in iter_regular_files(root):
        if not has_elf_magic(path):
            continue

        dyn_status, dyn_out = run_readelf(readelf, "-d", path)
        ph_status, ph_out = run_readelf(readelf, "-l", path)
        if dyn_status != 0 and ph_status != 0:
            continue

        needed, rpath, runpath, saw_dynamic_section = parse_dynamic_section(dyn_out)
        interpreter = parse_program_interpreter(ph_out)
        if not saw_dynamic_section and not interpreter:
            continue

        checked += 1
        display = relative_display(root, path)

        if interpreter:
            interp_path = rootfs_path(root, interpreter)
            if not is_under(interp_path, root) or not interp_path.exists():
                failures.append(f"missing ELF interpreter for {display}: {interpreter}")

        for library in needed:
            if not library_exists(root, path, library, rpath, runpath):
                failures.append(f"missing shared library for {display}: {library}")

    return checked, failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, help="materialized fs-tree root directory")
    parser.add_argument("--name", default="runtime-rootfs", help="name to show in reports")
    parser.add_argument("--readelf", default="readelf", help="readelf executable")
    args = parser.parse_args()

    root = pathlib.Path(args.root).resolve(strict=False)
    if not root.is_dir():
        print(f"runtime rootfs check: missing root directory: {root}", file=sys.stderr)
        return 2
    if shutil.which(args.readelf) is None:
        print(f"runtime rootfs check: missing readelf executable: {args.readelf}", file=sys.stderr)
        return 2

    symlink_count, symlink_failures = check_symlinks(root)
    elf_count, elf_failures = check_elf_files(root, args.readelf)
    failures = symlink_failures + elf_failures

    print("runtime rootfs check")
    print(f"name: {args.name}")
    print(f"root: {root}")
    print(f"readelf: {args.readelf}")
    print(f"symlinks checked: {symlink_count}")
    print(f"dynamic ELF files checked: {elf_count}")

    if failures:
        print("status: error")
        print(f"failures: {len(failures)}")
        for failure in failures:
            print(f"FAIL {failure}")
        return 1

    print("status: ok")
    print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
