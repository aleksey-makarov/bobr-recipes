#!/usr/bin/env python3

"""Boot the built EROFS rootfs artifact under qemu-system-x86_64."""

import json
import os
import pathlib
import re
import shutil
import subprocess
import sys


APPEND = (
    "root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay "
    "console=ttyS0 net.ifnames=0"
)
FS_TREE_SCHEMA = "bobr-fs-tree-manifest"
HEX_64_RE = re.compile(r"^[0-9a-f]{64}$")


def usage(program: str) -> str:
    return (
        f"usage: {program} [STORE] [-- QEMU_ARG ...]\n\n"
        "Boot pkgs.erofs_rootfs with pkgs.linux and pkgs.initrd.\n"
        "STORE defaults to ./mbuild-store relative to the current directory."
    )


def parse_args(argv: list[str]) -> tuple[pathlib.Path, list[str]]:
    if argv and argv[0] in {"-h", "--help"}:
        print(usage(pathlib.Path(sys.argv[0]).name))
        raise SystemExit(0)

    store = pathlib.Path.cwd() / "mbuild-store"
    qemu_args: list[str] = []

    if argv:
        if argv[0] == "--":
            qemu_args = argv[1:]
        else:
            store = pathlib.Path(argv[0])
            rest = argv[1:]
            if rest:
                if rest[0] != "--":
                    die(usage(pathlib.Path(sys.argv[0]).name))
                qemu_args = rest[1:]

    return store.expanduser().resolve(strict=False), qemu_args


def die(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def repo_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[1]


def load_recipe_names(root: pathlib.Path) -> dict[str, str]:
    expr = (
        'let pkgs = (import "pkgs.ncl") [] in '
        "{ linux = pkgs.linux.name, "
        "rootfs = pkgs.erofs_rootfs.name, "
        "initrd = pkgs.initrd.name }"
    )
    result = subprocess.run(
        ["nickel", "export", "--format", "json"],
        cwd=root,
        input=expr,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        die(result.stderr.rstrip() or "failed to query recipe artifact names")
    try:
        names = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        die(f"failed to parse nickel output: {error}")

    for key in ["linux", "rootfs", "initrd"]:
        if not isinstance(names.get(key), str) or not names[key]:
            die(f"nickel output does not contain a string '{key}' field")
    return names


def object_ref(store: pathlib.Path, name: str) -> pathlib.Path:
    return store / "object-refs" / name


def ensure_file(path: pathlib.Path, description: str) -> pathlib.Path:
    if not path.is_file():
        die(f"missing {description}: {path}")
    return path


def fs_tree_file_path(
    store: pathlib.Path, manifest_path: pathlib.Path, logical_path: str
) -> pathlib.Path:
    ensure_file(manifest_path, f"fs-tree manifest object for {logical_path}")
    matches: list[str] = []

    try:
        with manifest_path.open("r", encoding="utf-8") as manifest:
            header_line = manifest.readline()
            if not header_line:
                die(f"empty fs-tree manifest: {manifest_path}")
            header = json.loads(header_line)
            if header.get("schema") != FS_TREE_SCHEMA:
                die(f"not an fs-tree manifest: {manifest_path}")

            for line_number, line in enumerate(manifest, start=2):
                if not line.strip():
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError as error:
                    die(f"invalid fs-tree manifest line {line_number}: {error}")
                if entry.get("t") == "f" and entry.get("p") == logical_path:
                    hash_value = entry.get("h")
                    if not isinstance(hash_value, str) or not HEX_64_RE.match(hash_value):
                        die(
                            "invalid fs-file hash for "
                            f"{logical_path} in {manifest_path}:{line_number}"
                        )
                    matches.append(hash_value)
    except OSError as error:
        die(f"failed to read fs-tree manifest '{manifest_path}': {error}")
    except json.JSONDecodeError as error:
        die(f"invalid fs-tree manifest header in '{manifest_path}': {error}")

    if not matches:
        die(f"missing file '{logical_path}' in fs-tree manifest: {manifest_path}")
    if len(matches) > 1:
        die(f"duplicate file '{logical_path}' in fs-tree manifest: {manifest_path}")

    hash_value = matches[0]
    path = store / "fs-files" / hash_value[:2] / hash_value
    return ensure_file(path, f"fs-file object for {logical_path}")


def main(argv: list[str]) -> int:
    store, qemu_args = parse_args(argv)
    names = load_recipe_names(repo_root())

    rootfs_path = ensure_file(
        object_ref(store, names["rootfs"]),
        f"EROFS rootfs artifact for {names['rootfs']}",
    )
    initrd_path = ensure_file(
        object_ref(store, names["initrd"]), f"initrd artifact for {names['initrd']}"
    )
    kernel_path = fs_tree_file_path(store, object_ref(store, names["linux"]), "boot/bzImage")

    qemu_bin = shutil.which("qemu-system-x86_64")
    if qemu_bin is None:
        die("qemu-system-x86_64 not found in PATH")
    if not pathlib.Path("/dev/kvm").exists():
        die("/dev/kvm is not available; this smoke check requires KVM acceleration")

    mem_mb = os.environ.get("QEMU_MEM_MB", "1024")
    smp_count = os.environ.get("QEMU_SMP", "2")

    command = [
        qemu_bin,
        "-enable-kvm",
        "-cpu",
        "host",
        "-m",
        mem_mb,
        "-smp",
        smp_count,
        "-kernel",
        str(kernel_path),
        "-initrd",
        str(initrd_path),
        "-drive",
        f"file={rootfs_path},format=raw,if=virtio,readonly=on",
        "-nic",
        "user,model=virtio-net-pci",
        "-append",
        APPEND,
        "-nographic",
        "-no-reboot",
        *qemu_args,
    ]
    os.execv(qemu_bin, command)
    raise AssertionError("execv returned unexpectedly")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
