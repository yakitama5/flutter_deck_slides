#!/usr/bin/env python3
"""Exercise private asset restoration with synthetic files, never the real model."""

import io
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

import private_assets


class ArchiveValidationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.archive = Path(self.temp.name) / "fixture.tar.gz"
        self.files = {
            name: f"synthetic content for {name}\n".encode()
            for name in private_assets.PRIVATE_FILES
        }

    def write_archive(self, entries):
        with tarfile.open(self.archive, "w:gz") as archive:
            for name, data, kind in entries:
                member = tarfile.TarInfo(name)
                member.type = kind
                if kind in (tarfile.SYMTYPE, tarfile.LNKTYPE):
                    member.linkname = "/tmp/outside-private-asset-fixture"
                elif kind == tarfile.REGTYPE:
                    member.size = len(data)
                archive.addfile(member, io.BytesIO(data))

    def entries(self):
        return [
            (name, data, tarfile.REGTYPE) for name, data in self.files.items()
        ]

    def test_valid_archive_returns_the_original_bytes(self):
        self.write_archive(self.entries())
        self.assertEqual(private_assets.read_archive(self.archive), self.files)

    def test_duplicate_entries_are_rejected_even_when_contents_match(self):
        entries = self.entries()
        self.write_archive(entries + [entries[0]])
        with self.assertRaises(private_assets.AssetError):
            private_assets.read_archive(self.archive)

    def test_unexpected_and_escaping_paths_are_rejected(self):
        for name in ("reference.png", "../outside", "/absolute/path"):
            with self.subTest(name=name):
                self.write_archive(self.entries() + [(name, b"extra", tarfile.REGTYPE)])
                with self.assertRaises(private_assets.AssetError):
                    private_assets.read_archive(self.archive)

    def test_incomplete_and_empty_assets_are_rejected(self):
        entries = self.entries()
        variants = (entries[:-1], [(entries[0][0], b"", tarfile.REGTYPE)] + entries[1:])
        for entries in variants:
            with self.subTest(entries=len(entries)):
                self.write_archive(entries)
                with self.assertRaises(private_assets.AssetError):
                    private_assets.read_archive(self.archive)

    def test_links_and_directories_cannot_replace_an_asset(self):
        entries = self.entries()
        for kind in (tarfile.SYMTYPE, tarfile.LNKTYPE, tarfile.DIRTYPE):
            with self.subTest(kind=kind):
                self.write_archive([(entries[0][0], b"", kind)] + entries[1:])
                with self.assertRaises(private_assets.AssetError):
                    private_assets.read_archive(self.archive)

    def test_invalid_compressed_input_reports_an_asset_error(self):
        self.archive.write_bytes(b"not a gzip archive")
        with self.assertRaises(private_assets.AssetError):
            private_assets.read_archive(self.archive)


@unittest.skipUnless(shutil.which("gpg"), "GnuPG is required for encrypted round trips")
class EncryptionRoundTripTest(unittest.TestCase):
    passphrase = b"synthetic-private-assets-test-key"

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = (Path(self.temp.name) / "repository").resolve()
        self.root.mkdir()
        self.files = {
            name: f"synthetic private asset: {name}\n".encode()
            for name in private_assets.PRIVATE_FILES
        }
        for name, data in self.files.items():
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)

    def snapshot(self):
        return {
            name: (self.root / name).read_bytes() if (self.root / name).is_file() else None
            for name in self.files
        }

    def test_pack_only_includes_the_allowed_assets_and_round_trips(self):
        reference = (self.root / private_assets.PRIVATE_FILES[0]).parent / "reference.png"
        reference.write_bytes(b"must remain local")
        encrypted = private_assets.pack(self.root, self.passphrase)
        self.assertEqual(encrypted, self.root / private_assets.BUNDLE_PATH)

        # Inspect the real encrypted archive, not an implementation mock.
        gnupg_home = Path(self.temp.name) / "gnupg-inspection"
        gnupg_home.mkdir(mode=0o700)
        decrypted = subprocess.run(
            [
                "gpg", "--batch", "--no-options", "--homedir", str(gnupg_home),
                "--pinentry-mode", "loopback", "--passphrase-fd", "0",
                "--decrypt", str(encrypted),
            ],
            input=self.passphrase + b"\n",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        ).stdout
        with tarfile.open(fileobj=io.BytesIO(decrypted), mode="r:gz") as archive:
            self.assertEqual(set(archive.getnames()), set(self.files))

        for name in self.files:
            (self.root / name).unlink()
        private_assets.restore(self.root, self.passphrase)
        self.assertEqual(self.snapshot(), self.files)
        self.assertEqual(reference.read_bytes(), b"must remain local")
        # Restoring the same archive again must also succeed without --force.
        private_assets.restore(self.root, self.passphrase)
        self.assertEqual(self.snapshot(), self.files)

    def test_wrong_passphrase_and_truncated_bundle_preserve_local_files(self):
        encrypted = private_assets.pack(self.root, self.passphrase)
        original_ciphertext = encrypted.read_bytes()
        before = self.snapshot()
        with self.assertRaises(private_assets.AssetError):
            private_assets.restore(self.root, b"wrong synthetic key", force=True)
        self.assertEqual(self.snapshot(), before)

        encrypted.write_bytes(original_ciphertext[: len(original_ciphertext) // 2])
        with self.assertRaises(private_assets.AssetError):
            private_assets.restore(self.root, self.passphrase, force=True)
        self.assertEqual(self.snapshot(), before)

    def test_local_changes_abort_before_any_assets_are_written(self):
        private_assets.pack(self.root, self.passphrase)
        first, last = private_assets.PRIVATE_FILES[0], private_assets.PRIVATE_FILES[-1]
        (self.root / first).unlink()
        (self.root / last).write_bytes(b"uncommitted local edits")
        before = self.snapshot()
        with self.assertRaises(private_assets.AssetError):
            private_assets.restore(self.root, self.passphrase)
        self.assertEqual(self.snapshot(), before)

        private_assets.restore(self.root, self.passphrase, force=True)
        self.assertEqual(self.snapshot(), self.files)

    def test_pack_refuses_symlinked_assets_and_parents(self):
        encrypted = private_assets.pack(self.root, self.passphrase)
        before = encrypted.read_bytes()
        first = self.root / private_assets.PRIVATE_FILES[0]
        outside = Path(self.temp.name) / "outside-asset"
        outside.write_bytes(first.read_bytes())
        first.unlink()
        first.symlink_to(outside)
        with self.assertRaises(private_assets.AssetError):
            private_assets.pack(self.root, self.passphrase)
        self.assertEqual(encrypted.read_bytes(), before)

        first.unlink()
        first.write_bytes(self.files[private_assets.PRIVATE_FILES[0]])
        real_parent = Path(self.temp.name) / "outside-models"
        first.parent.rename(real_parent)
        first.parent.symlink_to(real_parent, target_is_directory=True)
        with self.assertRaises(private_assets.AssetError):
            private_assets.pack(self.root, self.passphrase)
        self.assertEqual(encrypted.read_bytes(), before)

    def test_restore_refuses_symlinked_targets_even_with_force(self):
        private_assets.pack(self.root, self.passphrase)
        first = self.root / private_assets.PRIVATE_FILES[0]
        outside = Path(self.temp.name) / "outside-target"
        outside.write_bytes(b"outside content must survive")
        first.unlink()
        first.symlink_to(outside)
        with self.assertRaises(private_assets.AssetError):
            private_assets.restore(self.root, self.passphrase, force=True)
        self.assertEqual(outside.read_bytes(), b"outside content must survive")

        first.unlink()
        parent = first.parent
        external_parent = Path(self.temp.name) / "outside-target-directory"
        parent.rename(external_parent)
        parent.symlink_to(external_parent, target_is_directory=True)
        with self.assertRaises(private_assets.AssetError):
            private_assets.restore(self.root, self.passphrase, force=True)
        self.assertFalse((external_parent / first.name).exists())

    def test_non_directory_parent_aborts_before_any_assets_are_restored(self):
        private_assets.pack(self.root, self.passphrase)
        for name in self.files:
            (self.root / name).unlink()
        source_parent = (self.root / private_assets.PRIVATE_FILES[-1]).parent
        source_parent.rmdir()
        source_parent.write_bytes(b"local file occupying the source directory")
        before = self.snapshot()
        with self.assertRaises(private_assets.AssetError):
            private_assets.restore(self.root, self.passphrase)
        self.assertEqual(self.snapshot(), before)
        self.assertEqual(
            source_parent.read_bytes(), b"local file occupying the source directory"
        )


if __name__ == "__main__":
    unittest.main()
