#!/usr/bin/env python3
"""Archive scoped prayer/event background images and convert them to WebP q90.

This migration intentionally only touches:
  - assets/prayerTimeChangeable/
  - assets/background/ramadan/
  - assets/background/eid/

Original files are copied to ../original_images_before_webp/assets/... before
any source file is removed or replaced.
"""

from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, features


QUALITY = 90
SCOPES = (
    Path("assets/prayerTimeChangeable"),
    Path("assets/background/ramadan"),
    Path("assets/background/eid"),
)
CONVERT_EXTENSIONS = {".png", ".jpg", ".jpeg"}


@dataclass(frozen=True)
class ConvertedImage:
    source: str
    archive: str
    output: str
    original_size: int
    webp_size: int
    original_format: str
    normalized_existing_webp: bool


def main() -> int:
    if not features.check("webp"):
        raise SystemExit("This Pillow runtime does not support WebP encoding.")

    project_root = Path.cwd().resolve()
    archive_root = project_root.parent / "original_images_before_webp"
    converted: list[ConvertedImage] = []

    candidates = discover_candidates(project_root)
    if not candidates:
        print("No images to convert.")
        return 0

    for source in candidates:
        converted.append(convert_image(project_root, archive_root, source))

    total_original = sum(item.original_size for item in converted)
    total_webp = sum(item.webp_size for item in converted)
    saved = total_original - total_webp

    summary = {
        "quality": QUALITY,
        "converted_count": len(converted),
        "original_total_bytes": total_original,
        "webp_total_bytes": total_webp,
        "saved_bytes": saved,
        "archive_root": str(archive_root),
        "items": [item.__dict__ for item in converted],
    }
    summary_path = archive_root / "migration_summary.json"
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Converted images: {len(converted)}")
    print(f"Original bytes: {total_original}")
    print(f"WebP bytes: {total_webp}")
    print(f"Saved bytes: {saved}")
    print(f"Archive: {archive_root}")
    print(f"Summary: {summary_path}")
    return 0


def discover_candidates(project_root: Path) -> list[Path]:
    candidates: list[Path] = []
    for scope in SCOPES:
        scope_path = project_root / scope
        if not scope_path.exists():
            continue

        for path in scope_path.rglob("*"):
            if not path.is_file():
                continue

            suffix = path.suffix.lower()
            if suffix in CONVERT_EXTENSIONS:
                candidates.append(path)
                continue

            if suffix == ".webp" and actual_format(path) in {"PNG", "JPEG"}:
                candidates.append(path)

    return sorted(candidates, key=lambda item: item.as_posix().lower())


def actual_format(path: Path) -> str:
    try:
        with Image.open(path) as image:
            return image.format or ""
    except Exception:
        return ""


def convert_image(
    project_root: Path,
    archive_root: Path,
    source: Path,
) -> ConvertedImage:
    relative = source.relative_to(project_root)
    archive_path = archive_root / relative

    if archive_path.exists():
        raise SystemExit(f"Archive already exists, refusing to overwrite: {archive_path}")

    with Image.open(source) as image:
        original_format = image.format or ""
        converted_image = image.convert("RGB")

        original_size = source.stat().st_size
        output_path = source if source.suffix.lower() == ".webp" else source.with_suffix(".webp")
        temp_path = output_path.with_name(f"{output_path.name}.tmp")

        if output_path != source and output_path.exists():
            raise SystemExit(f"Output already exists, refusing to overwrite: {output_path}")

        archive_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, archive_path)

        converted_image.save(
            temp_path,
            "WEBP",
            quality=QUALITY,
            method=6,
        )

    if output_path == source:
        source.unlink()
        temp_path.replace(output_path)
        normalized_existing_webp = True
    else:
        temp_path.replace(output_path)
        source.unlink()
        normalized_existing_webp = False

    return ConvertedImage(
        source=relative.as_posix(),
        archive=archive_path.relative_to(archive_root).as_posix(),
        output=output_path.relative_to(project_root).as_posix(),
        original_size=original_size,
        webp_size=output_path.stat().st_size,
        original_format=original_format,
        normalized_existing_webp=normalized_existing_webp,
    )


if __name__ == "__main__":
    raise SystemExit(main())
