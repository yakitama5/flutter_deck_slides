#!/usr/bin/env python3
"""Pack/restore the private Dashmaru authoring files using an Actions secret.

Only the encrypted bundle is tracked. The passphrase travels to GPG over stdin,
never in an argument or in output. GPG and Python's standard library are enough.
"""

import argparse
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = "slides/20260919_flutterkaigi_mini"
PRIVATE_FILES = (
    f"{MODEL_DIR}/assets/models/dashmaru.glb",
    f"{MODEL_DIR}/assets/models/dashmaru_manifest.json",
    f"{MODEL_DIR}/tool/build_dashmaru.py",
    f"{MODEL_DIR}/tool/dashmaru_expressions.py",
    f"{MODEL_DIR}/tool/dashmaru_materials.py",
)
BUNDLE_PATH = ".private-assets/dashmaru.tar.gz.gpg"
SECRET_NAME = "DASHMARU_ASSET_PASSPHRASE"
MAX_FILE_BYTES = 64 * 1024 * 1024
MAX_ARCHIVE_BYTES = 96 * 1024 * 1024


class AssetError(Exception):
    """Private assets could not be safely packed or restored."""


def safe_target(root, name):
    """Reject links before reading or replacing anything in the checkout."""
    target = root
    parts = Path(name).parts
    for index, part in enumerate(parts):
        target = target / part
        if target.is_symlink():
            raise AssetError(f"Asset path must not contain a symlink: {name}")
        if index < len(parts) - 1 and target.exists() and not target.is_dir():
            raise AssetError(f"Asset parent must be a directory: {name}")
    if target.exists() and not target.is_file():
        raise AssetError(f"Expected a regular file: {name}")
    return target


def read_archive(path):
    """Read exactly the allowlisted files; never extract arbitrary tar paths."""
    payload = {}
    total = 0
    try:
        with tarfile.open(path, "r:gz") as archive:
            for member in archive:
                if member.name not in PRIVATE_FILES or member.name in payload:
                    raise AssetError("Bundle has an unexpected or duplicate path")
                if not member.isfile() or not 0 < member.size <= MAX_FILE_BYTES:
                    raise AssetError("Bundle contains a link, empty or oversized file")
                total += member.size
                if total > MAX_ARCHIVE_BYTES:
                    raise AssetError("Bundle exceeds the uncompressed size limit")
                stream = archive.extractfile(member)
                if stream is None:
                    raise AssetError("Bundle member could not be read")
                with stream:
                    contents = stream.read(member.size + 1)
                if len(contents) != member.size:
                    raise AssetError("Bundle contains a truncated file")
                payload[member.name] = contents
    except (tarfile.TarError, EOFError, OSError) as error:
        raise AssetError("Bundle is not a readable tar.gz archive") from error
    if set(payload) != set(PRIVATE_FILES):
        raise AssetError("Bundle is missing required authoring files")
    return payload


def crypt(source, destination, passphrase, *, encrypt):
    if not passphrase or b"\n" in passphrase or b"\r" in passphrase:
        raise AssetError("A nonempty, single-line asset passphrase is required")
    gpg = shutil.which("gpg")
    if gpg is None:
        raise AssetError("GPG is required (macOS: brew install gnupg)")
    # Isolate GPG configuration, keyrings and caches from the developer's setup.
    with tempfile.TemporaryDirectory(prefix="dashmaru-gpg-") as keyring:
        command = [
            gpg,
            "--no-options",
            "--homedir", keyring,
            "--batch", "--yes", "--quiet",
            "--pinentry-mode", "loopback",
            "--no-symkey-cache",
            "--passphrase-fd", "0",
            "--output", str(destination),
        ]
        if encrypt:
            command.extend([
                "--symmetric", "--rfc4880", "--cipher-algo", "AES256",
                "--compress-algo", "none",
                "--s2k-digest-algo", "SHA512",
            ])
        else:
            command.append("--decrypt")
        command.append(str(source))
        environment = os.environ.copy()
        environment.pop(SECRET_NAME, None)
        result = subprocess.run(
            command,
            input=passphrase + b"\n",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            check=False,
        )
        if result.returncode:
            action = "encryption" if encrypt else "decryption"
            raise AssetError(f"GPG {action} failed; check the passphrase and bundle")


def pack(root, passphrase):
    root = Path(root).resolve()
    payload = {}
    for name in PRIVATE_FILES:
        path = safe_target(root, name)
        if not path.is_file() or not 0 < path.stat().st_size <= MAX_FILE_BYTES:
            raise AssetError(f"Missing, empty or oversized authoring file: {name}")
        payload[name] = path.read_bytes()
    if sum(map(len, payload.values())) > MAX_ARCHIVE_BYTES:
        raise AssetError("Authoring files exceed the size limit")
    bundle = safe_target(root, BUNDLE_PATH)
    bundle.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".pack-", dir=bundle.parent) as work:
        archive = Path(work) / "authoring.tar.gz"
        with tarfile.open(archive, "w:gz", format=tarfile.USTAR_FORMAT) as tar:
            for name, contents in payload.items():
                member = tarfile.TarInfo(name)
                member.size = len(contents)
                member.mode = 0o600
                tar.addfile(member, io.BytesIO(contents))
        encrypted = Path(work) / "bundle.gpg"
        crypt(archive, encrypted, passphrase, encrypt=True)
        # Verify the actual ciphertext before replacing a working bundle.
        verified = Path(work) / "verified.tar.gz"
        crypt(encrypted, verified, passphrase, encrypt=False)
        if read_archive(verified) != payload:
            raise AssetError("Encrypted bundle failed the round-trip check")
        os.replace(encrypted, bundle)
    return bundle


def restore(root, passphrase, force=False):
    root = Path(root).resolve()
    bundle = safe_target(root, BUNDLE_PATH)
    if not bundle.is_file():
        raise AssetError(f"Encrypted bundle is missing: {BUNDLE_PATH}")
    with tempfile.TemporaryDirectory(prefix="dashmaru-restore-") as work:
        archive = Path(work) / "authoring.tar.gz"
        crypt(bundle, archive, passphrase, encrypt=False)
        payload = read_archive(archive)
    # Validate every destination and local edit before writing the first file.
    targets = {name: safe_target(root, name) for name in PRIVATE_FILES}
    for name, path in targets.items():
        if path.exists() and path.read_bytes() != payload[name] and not force:
            raise AssetError(
                f"Local authoring changes would be overwritten: {name}; "
                "back them up or use --force intentionally"
            )
    for name, path in targets.items():
        if path.exists() and path.read_bytes() == payload[name]:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as out:
                temporary = Path(out.name)
                out.write(payload[name])
            os.replace(temporary, path)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    return list(PRIVATE_FILES)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("pack", "restore"))
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--passphrase-file", type=Path)
    parser.add_argument("--force", action="store_true", help="Restore over local edits")
    args = parser.parse_args()
    try:
        if args.passphrase_file:
            passphrase = args.passphrase_file.read_bytes().rstrip(b"\r\n")
        else:
            passphrase = os.environ.get(SECRET_NAME, "").encode()
        if not passphrase:
            raise AssetError(f"Set {SECRET_NAME} or provide --passphrase-file")
        if args.command == "pack":
            pack(args.root, passphrase)
            print(f"Packed and verified {len(PRIVATE_FILES)} files into {BUNDLE_PATH}")
        else:
            restore(args.root, passphrase, force=args.force)
            print(f"Restored {len(PRIVATE_FILES)} private Dashmaru authoring files")
    except (AssetError, OSError) as error:
        parser.exit(1, f"Private assets: {error}\n")


if __name__ == "__main__":
    main()
