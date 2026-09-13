#!/usr/bin/env python3
"""Select slide apps affected by a PR; shared/build changes select every app."""

import json
import os
import subprocess
from pathlib import Path


def select_slides(paths, available):
    selected = set()
    shared = ("packages/", "tool/", ".github/workflows/")
    root_build_files = {
        "pubspec.yaml",
        "pubspec.lock",
        "mise.toml",
        "analysis_options.yaml",
    }
    for path in paths:
        if path.startswith(shared) or path in root_build_files:
            return sorted(available)
        parts = path.split("/")
        if len(parts) >= 2 and parts[0] == "slides":
            if parts[1] not in available:
                # A removed app must also disappear from the preview index.
                return sorted(available)
            selected.add(parts[1])
    return sorted(selected)


def main():
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    base = event["pull_request"]["base"]["sha"]
    paths = subprocess.check_output(
        ["git", "diff", "--name-only", "--no-renames", f"{base}...HEAD"], text=True
    ).splitlines()
    available = {
        p.name for p in Path("slides").iterdir() if (p / "pubspec.yaml").is_file()
    }
    selected = select_slides(paths, available)
    # PRs without web changes keep CI checks but skip the preview build/upload.
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"slides={','.join(selected)}\n")
        output.write(f"has_slides={'true' if selected else 'false'}\n")
    print(f"Preview slides: {', '.join(selected) or '(no web changes)'}")


if __name__ == "__main__":
    main()
