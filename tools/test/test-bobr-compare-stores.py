#!/usr/bin/env python3
"""Regression tests for the current direct-to-objects mapping layout."""

from __future__ import annotations

import importlib.util
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bobr-compare-stores.py"
SPEC = importlib.util.spec_from_file_location("bobr_compare_stores", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
compare = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(compare)


class CompareStoresTests(unittest.TestCase):
    def make_store(
        self,
        root: Path,
        build_key: str,
        object_hash: str,
        inputs: list[str],
        *,
        record_build_key: str | None = None,
    ) -> None:
        for name in ("builds", "object-records", "object-refs", "objects"):
            (root / name).mkdir(parents=True, exist_ok=True)
        # A directory payload catches accidental DirEntry.is_file() calls,
        # which follow the mapping symlink and reject directory objects.
        (root / "objects" / object_hash).mkdir()
        (root / "builds" / build_key).symlink_to(f"../objects/{object_hash}")
        record = {
            "schema": "bobr-object-record-v4",
            "build_key": record_build_key or build_key,
            "object_hash": object_hash,
            "inputs": inputs,
        }
        (root / "object-records" / f"{object_hash}.json").write_text(
            json.dumps(record)
        )

    def views(self, a: Path, b: Path):
        view_a = compare.StoreView(a, readers=1)
        view_b = compare.StoreView(b, readers=1)
        view_a.read_mappings(view_a.build_keys)
        view_b.read_mappings(view_b.build_keys)
        return view_a, view_b

    def test_directory_object_mappings_are_compared_as_root_divergence(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            a, b = root / "a", root / "b"
            build_key = "1" * 64
            inputs = ["2" * 64]
            self.make_store(a, build_key, "a" * 64, inputs)
            self.make_store(b, build_key, "b" * 64, inputs)
            view_a, view_b = self.views(a, b)

            output = io.StringIO()
            with redirect_stdout(output):
                result = compare.compare_objects(
                    view_a, view_b, {build_key}, False, 40, False
                )

            self.assertEqual(result, 1)
            self.assertIn("roots=1, inherited=0, unknown=0", output.getvalue())

    def test_record_for_another_build_key_gives_unknown_provenance(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            a, b = root / "a", root / "b"
            build_key = "1" * 64
            inputs = ["2" * 64]
            self.make_store(a, build_key, "a" * 64, inputs)
            self.make_store(
                b,
                build_key,
                "b" * 64,
                inputs,
                record_build_key="3" * 64,
            )
            view_a, view_b = self.views(a, b)

            output = io.StringIO()
            with redirect_stdout(output):
                result = compare.compare_objects(
                    view_a, view_b, {build_key}, False, 40, False
                )

            self.assertEqual(result, 1)
            self.assertIn("roots=0, inherited=0, unknown=1", output.getvalue())
            self.assertIn("different build key", output.getvalue())

    def test_matching_outputs_do_not_require_object_records(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            a, b = root / "a", root / "b"
            build_key = "1" * 64
            object_hash = "a" * 64
            self.make_store(a, build_key, object_hash, ["2" * 64])
            self.make_store(b, build_key, object_hash, ["2" * 64])
            (a / "object-records" / f"{object_hash}.json").unlink()
            (b / "object-records" / f"{object_hash}.json").unlink()
            view_a, view_b = self.views(a, b)

            output = io.StringIO()
            with redirect_stdout(output):
                result = compare.compare_objects(
                    view_a, view_b, {build_key}, False, 40, False
                )

            self.assertEqual(result, 0)
            self.assertIn("no divergences", output.getvalue())

    def test_non_symlink_mapping_is_reported_instead_of_crashing(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            a, b = root / "a", root / "b"
            build_key = "1" * 64
            inputs = ["2" * 64]
            self.make_store(a, build_key, "a" * 64, inputs)
            self.make_store(b, build_key, "a" * 64, inputs)
            (b / "builds" / build_key).unlink()
            (b / "builds" / build_key).write_text("not a symlink\n")
            view_a, view_b = self.views(a, b)

            output = io.StringIO()
            with redirect_stdout(output):
                result = compare.compare_objects(
                    view_a, view_b, {build_key}, False, 40, False
                )

            self.assertEqual(result, 1)
            self.assertIn("unreadable mappings: 1", output.getvalue())
            self.assertIn("cannot read mapping symlink", output.getvalue())


if __name__ == "__main__":
    unittest.main()
