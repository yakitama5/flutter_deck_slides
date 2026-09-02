#!/usr/bin/env python3
"""Build a human-review contact sheet for the three page candidates."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Sequence


VARIANTS = ("a", "b", "c")


class ContactSheetError(RuntimeError):
    """A contact-sheet input or dependency error."""


def make_contact_sheet(page_dir: Path, output_path: Path | None = None) -> Path:
    try:
        from PIL import Image, ImageDraw, ImageFont, ImageOps  # type: ignore
    except ImportError as exc:
        raise ContactSheetError(
            "Pillow is required to create contact_sheet.png; install generation/requirements.txt"
        ) from exc

    page_dir = page_dir.resolve()
    candidates = [page_dir / f"variant_{variant}.png" for variant in VARIANTS]
    missing = [str(path) for path in candidates if not path.is_file()]
    if missing:
        raise ContactSheetError("Missing candidate image(s): " + ", ".join(missing))
    output_path = output_path or page_dir / "contact_sheet.png"

    panel_width = 640
    panel_height = 360
    label_height = 38
    background = (250, 247, 238)
    sheet = Image.new(
        "RGB", (panel_width * len(candidates), panel_height + label_height), background
    )
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 22)
    except OSError:
        font = ImageFont.load_default()

    for index, (variant, candidate) in enumerate(zip(VARIANTS, candidates)):
        with Image.open(candidate) as source:
            image = ImageOps.contain(source.convert("RGB"), (panel_width, panel_height))
        left = index * panel_width
        top = (panel_height - image.height) // 2
        sheet.paste(image, (left + (panel_width - image.width) // 2, top))
        draw.rectangle((left, panel_height, left + panel_width, panel_height + label_height), fill=(235, 228, 211))
        draw.text((left + 16, panel_height + 7), f"Variant {variant.upper()}", fill=(45, 38, 31), font=font)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path, format="PNG", optimize=True)
    return output_path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--page", required=True, help="Page id, for example page05")
    parser.add_argument(
        "--storybook-dir",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help=argparse.SUPPRESS,
    )
    parser.add_argument("--output", type=Path, help="Optional contact sheet path")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        page_dir = args.storybook_dir.resolve() / "generation" / "output" / args.page
        output = make_contact_sheet(page_dir, args.output)
    except ContactSheetError as exc:
        print(f"error: {exc}")
        return 2
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
