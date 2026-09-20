"""Release packaging regressions; uses temporary fixtures, never real exports."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

import package_release


class PackageReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="storm-chaser-package-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.source.mkdir()
        previous_out = package_release.out
        package_release.out = self.root
        self.addCleanup(setattr, package_release, "out", previous_out)

    def test_nested_files_round_trip_with_portable_archive_names(self):
        nested = self.source / "nested folder"
        nested.mkdir()
        (nested / "payload.bin").write_bytes(b"\x00\xffpayload")
        record = package_release.package("release.zip", self.source, "Storm-Chaser")
        self.assertEqual(record["file_count"], 1)
        with zipfile.ZipFile(self.root / "release.zip") as archive:
            self.assertEqual(archive.namelist(), ["Storm-Chaser/nested folder/payload.bin"])
            self.assertEqual(archive.read(archive.namelist()[0]), b"\x00\xffpayload")

    def test_missing_source_does_not_replace_existing_archive(self):
        target = self.root / "release.zip"
        target.write_bytes(b"previous release")
        with self.assertRaisesRegex(ValueError, "source directory is missing"):
            package_release.package("release.zip", self.root / "absent", "Storm-Chaser")
        self.assertEqual(target.read_bytes(), b"previous release")

    def test_empty_source_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "no distributable files"):
            package_release.package("release.zip", self.source, "Storm-Chaser")
        self.assertFalse((self.root / "release.zip").exists())

    def test_source_with_only_excluded_files_is_rejected(self):
        (self.source / "old.zip").write_bytes(b"not a distributable file")
        cache = self.source / ".godot"
        cache.mkdir()
        (cache / "cache.bin").write_bytes(b"cached data")
        with self.assertRaisesRegex(ValueError, "no distributable files"):
            package_release.package("release.zip", self.source, "Storm-Chaser")

    def test_missing_or_empty_required_entry_is_rejected(self):
        (self.source / "README.txt").write_text("A readme alone is not an export.")
        for contents in (None, b""):
            with self.subTest(contents=contents):
                if contents is not None:
                    (self.source / "Storm-Chaser.exe").write_bytes(contents)
                with self.assertRaisesRegex(ValueError, "missing or empty"):
                    package_release.package(
                        "release.zip", self.source, "Storm-Chaser", ("Storm-Chaser.exe",)
                    )
                self.assertFalse((self.root / "release.zip").exists())

    def make_release(self):
        # A differently named checkout must still package its own source tree.
        project = self.root / "renamed-checkout"
        (project / "tools").mkdir(parents=True)
        script = project / "tools" / "package_release.py"
        shutil.copyfile(package_release.__file__, script)
        (project / "project.godot").write_text("config_version=5\n")
        exports = self.root / "exports"
        for platform, entries in package_release.EXPORT_ENTRIES.items():
            folder = exports / f"Storm-Chaser-{platform}"
            folder.mkdir(parents=True)
            for entry in entries:
                (folder / entry).write_bytes(b"fake export for packaging tests")
        (exports / "Storm-Chaser-v0.16.0-Solid-Impacts.mp4").write_bytes(b"fake preview")
        return script, exports

    def run_release(self, script):
        return subprocess.run(
            [sys.executable, "-B", str(script)], capture_output=True, text=True, check=False
        )

    def test_complete_release_packages_all_platforms_and_current_checkout(self):
        script, exports = self.make_release()
        result = self.run_release(script)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(list(exports.glob("*.zip"))), 4)
        with zipfile.ZipFile(exports / "Storm-Chaser-Godot-Project.zip") as archive:
            self.assertIn("Storm-Chaser/project.godot", archive.namelist())

    def test_missing_web_payload_preserves_previous_archives(self):
        script, exports = self.make_release()
        (exports / "Storm-Chaser-Web" / "index.wasm").unlink()
        previous_archive = exports / "Storm-Chaser-Windows.zip"
        previous_archive.write_bytes(b"previous release")
        result = self.run_release(script)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("index.wasm", result.stderr)
        self.assertEqual(previous_archive.read_bytes(), b"previous release")
        self.assertEqual(list(exports.glob("*.zip")), [previous_archive])


if __name__ == "__main__":
    unittest.main()
