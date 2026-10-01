#!/usr/bin/env python3
"""Regression tests for the current direct-to-objects mapping layout."""

from __future__ import annotations

import importlib.util
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "bobr-compare-stores.py"
SPEC = importlib.util.spec_from_file_location("bobr_compare_stores", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
compare = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(compare)


class CompareStoresTests(unittest.TestCase):
    def make_run(
        self,
        store: Path,
        run_id: str,
        *,
        outcome: str = "success",
        commit: str = "1" * 40,
        dirty: bool = False,
        names: dict[str, str] | None = None,
    ) -> None:
        run = store / "logs" / run_id
        run.mkdir(parents=True, exist_ok=True)
        (run / "context.json").write_text(json.dumps({
            "schema": "bobr-run-context-v1",
            "run_id": run_id,
            "target": "world",
            "outcome": outcome,
            "exit_status": 0 if outcome == "success" else 1,
            "bobr": {
                "version": "test",
                "request_schema": "bobr-request-v6",
                "provenance": None,
            },
            "recipes": {
                "git_commit": commit,
                "git_dirty": dirty,
            },
        }))
        nodes = {
            f"n{index}": {"name": name, "tag": tag}
            for index, (name, tag) in enumerate((names or {}).items())
        }
        (run / "recipe-catalog.json").write_text(json.dumps({
            "schema": "bobr-recipe-catalog-v1",
            "nodes": nodes,
        }))

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

    def test_run_contexts_are_deduplicated_and_keep_outcomes(self):
        with tempfile.TemporaryDirectory() as temporary:
            store = Path(temporary)
            self.make_run(store, "one")
            self.make_run(store, "two", outcome="failed")
            self.make_run(store, "three", commit="2" * 40, dirty=True)

            identities, outcomes, warnings, source = (
                compare.load_build_contexts(store, readers=2)
            )

            self.assertEqual(source, "run logs")
            self.assertEqual(outcomes, {"success": 2, "failed": 1})
            self.assertEqual(len(identities["bobr"]), 1)
            self.assertEqual(
                identities["bobr-recipes"],
                {"1" * 40, "2" * 40 + "-dirty"},
            )
            self.assertEqual(warnings, [])

    def test_legacy_hashes_are_used_only_without_run_contexts(self):
        with tempfile.TemporaryDirectory() as temporary:
            store = Path(temporary)
            (store / "hashes.txt").write_text(
                "bobr deadbeef\nbobr-recipes cafeaffe\n"
            )

            identities, outcomes, warnings, source = (
                compare.load_build_contexts(store, readers=1)
            )

            self.assertEqual(source, "legacy hashes.txt")
            self.assertEqual(identities["bobr"], {"deadbeef"})
            self.assertEqual(identities["bobr-recipes"], {"cafeaffe"})
            self.assertEqual(outcomes, {})
            self.assertEqual(warnings, [])

    def test_missing_logs_are_diagnostic_only(self):
        with tempfile.TemporaryDirectory() as temporary:
            store = Path(temporary)
            identities, outcomes, warnings, source = (
                compare.load_build_contexts(store, readers=1)
            )

            self.assertEqual(source, "unavailable")
            self.assertEqual(identities["bobr"], set())
            self.assertEqual(outcomes, {})
            self.assertIn("run logs directory is unavailable", warnings[0])

    def test_main_compares_stores_without_logs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            a, b = root / "a", root / "b"
            (a / "builds").mkdir(parents=True)
            (b / "builds").mkdir(parents=True)
            output = io.StringIO()

            with patch.object(sys, "argv", [str(SCRIPT), str(a), str(b)]):
                with redirect_stdout(output):
                    result = compare.main()

            self.assertEqual(result, 0)
            self.assertIn("run logs directory is unavailable", output.getvalue())
            self.assertIn("stores reproduce identically", output.getvalue())

    def test_conflicting_catalog_tags_are_reported_as_ambiguous(self):
        with tempfile.TemporaryDirectory() as temporary:
            store = Path(temporary)
            self.make_run(store, "one", names={"compiler": "Sandbox"})
            self.make_run(store, "two", names={"compiler": "Bundle"})
            view = compare.StoreView(store, readers=2)
            resolver = compare.Resolver([view])

            self.assertEqual(
                resolver.tag("compiler"),
                "ambiguous: Bundle, Sandbox",
            )
            self.assertEqual(view.metadata_warnings, [])


if __name__ == "__main__":
    unittest.main()
