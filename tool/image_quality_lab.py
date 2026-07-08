#!/usr/bin/env python3
"""Non-destructive WebP quality comparison lab.

Usage:
  python tool/image_quality_lab.py path/to/image.png
  python tool/image_quality_lab.py path/to/folder

Outputs are written to image_quality_lab_output/ in the current directory.
Original image files are copied for comparison and are never modified.
"""

from __future__ import annotations

import argparse
import html
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, features
except ImportError as exc:  # pragma: no cover - only hit on missing tooling.
    raise SystemExit(
        "Pillow is required to run this tool. Install Pillow or use the "
        "bundled Codex Python runtime that includes it."
    ) from exc


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
QUALITIES = (80, 85, 90, 95)
OUTPUT_DIR = Path("image_quality_lab_output")
MAX_WIDTH = 2400


@dataclass(frozen=True)
class Variant:
    quality: int
    path: Path
    size: int
    saved_percent: float


@dataclass(frozen=True)
class ImageReport:
    source: Path
    output_dir: Path
    original_copy: Path
    original_size: int
    width: int
    height: int
    encoded_width: int
    encoded_height: int
    resized_for_webp: bool
    variants: tuple[Variant, ...]
    recommendation: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create WebP quality comparison outputs without modifying originals."
    )
    parser.add_argument(
        "input",
        type=Path,
        help="Input image file or folder containing images.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_DIR,
        help="Output folder. Defaults to image_quality_lab_output/.",
    )
    parser.add_argument(
        "--recursive",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Recursively scan folders. Default: true.",
    )
    return parser.parse_args()


def discover_images(input_path: Path, recursive: bool) -> list[Path]:
    if input_path.is_file():
        if input_path.suffix.lower() not in IMAGE_EXTENSIONS:
            raise SystemExit(f"Unsupported image extension: {input_path}")
        return [input_path]

    if not input_path.is_dir():
        raise SystemExit(f"Input path does not exist: {input_path}")

    pattern = "**/*" if recursive else "*"
    images = [
        path
        for path in input_path.glob(pattern)
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    ]
    return sorted(images, key=lambda path: str(path).lower())


def unique_image_dir(output_root: Path, image_path: Path, index: int) -> Path:
    safe_name = "".join(
        char if char.isalnum() or char in ("-", "_") else "_"
        for char in image_path.stem
    ).strip("_")
    safe_name = safe_name or "image"
    return output_root / f"{index:03d}_{safe_name}"


def resize_if_needed(image: Image.Image) -> tuple[Image.Image, bool]:
    width, height = image.size
    if width <= MAX_WIDTH:
        return image.copy(), False

    new_height = round(height * (MAX_WIDTH / width))
    resized = image.resize((MAX_WIDTH, new_height), Image.Resampling.LANCZOS)
    return resized, True


def save_webp_variants(
    source_image: Image.Image,
    image_dir: Path,
    stem: str,
    original_size: int,
) -> tuple[Variant, ...]:
    variants: list[Variant] = []
    image_for_webp = source_image.convert("RGB")

    for quality in QUALITIES:
        output_path = image_dir / f"{stem}_q{quality}.webp"
        image_for_webp.save(
            output_path,
            "WEBP",
            quality=quality,
            method=6,
        )
        size = output_path.stat().st_size
        saved = percent_saved(original_size, size)
        variants.append(
            Variant(
                quality=quality,
                path=output_path,
                size=size,
                saved_percent=saved,
            )
        )

    return tuple(variants)


def percent_saved(original_size: int, new_size: int) -> float:
    if original_size <= 0:
        return 0.0
    return ((original_size - new_size) / original_size) * 100


def choose_recommendation(variants: Iterable[Variant]) -> str:
    by_quality = {variant.quality: variant for variant in variants}
    q80 = by_quality[80]
    q85 = by_quality[85]
    q90 = by_quality[90]
    q95 = by_quality[95]

    if q85.saved_percent >= q90.saved_percent + 6:
        return "q85"
    if q80.saved_percent >= q85.saved_percent + 8:
        return "q80"
    if q90.saved_percent >= 25:
        return "q90"
    if q95.saved_percent >= 15:
        return "q95"
    return "q90"


def process_image(image_path: Path, output_root: Path, index: int) -> ImageReport:
    image_dir = unique_image_dir(output_root, image_path, index)
    image_dir.mkdir(parents=True, exist_ok=True)

    original_size = image_path.stat().st_size
    original_copy = image_dir / f"original{image_path.suffix.lower()}"
    shutil.copy2(image_path, original_copy)

    with Image.open(image_path) as image:
        width, height = image.size
        source_for_webp, resized_for_webp = resize_if_needed(image)
        encoded_width, encoded_height = source_for_webp.size

        variants = save_webp_variants(
            source_image=source_for_webp,
            image_dir=image_dir,
            stem=image_path.stem,
            original_size=original_size,
        )

    return ImageReport(
        source=image_path,
        output_dir=image_dir,
        original_copy=original_copy,
        original_size=original_size,
        width=width,
        height=height,
        encoded_width=encoded_width,
        encoded_height=encoded_height,
        resized_for_webp=resized_for_webp,
        variants=variants,
        recommendation=choose_recommendation(variants),
    )


def human_size(num_bytes: int) -> str:
    units = ("B", "KiB", "MiB", "GiB")
    value = float(num_bytes)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.1f} {unit}" if unit != "B" else f"{num_bytes} B"
        value /= 1024
    return f"{num_bytes} B"


def rel(path: Path, base: Path) -> str:
    return path.relative_to(base).as_posix()


def write_report(reports: list[ImageReport], output_root: Path) -> None:
    lines = [
        "# Image Quality Lab Report",
        "",
        f"Images tested: {len(reports)}",
        f"Qualities: {', '.join(f'q{q}' for q in QUALITIES)}",
        f"Resize rule: images wider than {MAX_WIDTH}px are encoded at {MAX_WIDTH}px wide; smaller images are not resized.",
        "",
        "| Image | Dimensions | Encoded Dimensions | Original Size | q80 Size | q80 Saved | q85 Size | q85 Saved | q90 Size | q90 Saved | q95 Size | q95 Saved | Recommended |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]

    for report in reports:
        by_quality = {variant.quality: variant for variant in report.variants}
        resized_note = " resized" if report.resized_for_webp else ""
        lines.append(
            "| "
            + " | ".join(
                [
                    report.source.name,
                    f"{report.width}x{report.height}",
                    f"{report.encoded_width}x{report.encoded_height}{resized_note}",
                    human_size(report.original_size),
                    human_size(by_quality[80].size),
                    f"{by_quality[80].saved_percent:.1f}%",
                    human_size(by_quality[85].size),
                    f"{by_quality[85].saved_percent:.1f}%",
                    human_size(by_quality[90].size),
                    f"{by_quality[90].saved_percent:.1f}%",
                    human_size(by_quality[95].size),
                    f"{by_quality[95].saved_percent:.1f}%",
                    report.recommendation,
                ]
            )
            + " |"
        )

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- Original files are copied into the output folder for comparison.",
            "- Original app assets are never modified.",
            "- The recommendation is size-based only; inspect `compare.html` before applying compression broadly.",
        ]
    )

    (output_root / "report.md").write_text("\n".join(lines), encoding="utf-8")


def write_html(reports: list[ImageReport], output_root: Path) -> None:
    cards: list[str] = []
    for report in reports:
        figure_parts = [
            image_figure(
                title="Original",
                image_path=report.original_copy,
                size=report.original_size,
                output_root=output_root,
                extra=f"{report.width}x{report.height}",
            )
        ]

        for variant in report.variants:
            figure_parts.append(
                image_figure(
                    title=f"WebP q{variant.quality}",
                    image_path=variant.path,
                    size=variant.size,
                    output_root=output_root,
                    extra=f"{variant.saved_percent:.1f}% saved",
                )
            )

        resize_note = (
            f"<p class=\"note\">WebP variants were resized to {report.encoded_width}x{report.encoded_height}.</p>"
            if report.resized_for_webp
            else "<p class=\"note\">No resize was applied.</p>"
        )

        cards.append(
            f"""
            <section class="image-card">
              <h2>{html.escape(report.source.name)}</h2>
              {resize_note}
              <div class="grid">
                {''.join(figure_parts)}
              </div>
            </section>
            """
        )

    html_text = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Image Quality Lab</title>
  <style>
    body {{
      margin: 0;
      font-family: Arial, sans-serif;
      background: #f5f5f5;
      color: #1f2933;
    }}
    header {{
      padding: 24px;
      background: #111827;
      color: white;
    }}
    main {{
      padding: 20px;
    }}
    .image-card {{
      background: white;
      border-radius: 10px;
      padding: 16px;
      margin-bottom: 20px;
      box-shadow: 0 8px 24px rgba(15, 23, 42, 0.08);
    }}
    h1, h2 {{
      margin: 0 0 8px;
    }}
    .note {{
      margin: 0 0 14px;
      color: #52606d;
    }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 14px;
      align-items: start;
    }}
    figure {{
      margin: 0;
      border: 1px solid #d9e2ec;
      border-radius: 8px;
      overflow: hidden;
      background: #fff;
    }}
    img {{
      display: block;
      width: 100%;
      height: auto;
      background: #e5e7eb;
    }}
    figcaption {{
      padding: 10px;
      font-size: 13px;
      line-height: 1.45;
    }}
    .label {{
      font-weight: 700;
    }}
  </style>
</head>
<body>
  <header>
    <h1>Image Quality Lab</h1>
    <p>Non-destructive WebP comparison: original, q80, q85, q90, q95.</p>
  </header>
  <main>
    {''.join(cards)}
  </main>
</body>
</html>
"""
    (output_root / "compare.html").write_text(html_text, encoding="utf-8")


def image_figure(
    *,
    title: str,
    image_path: Path,
    size: int,
    output_root: Path,
    extra: str,
) -> str:
    return f"""
    <figure>
      <img src="{html.escape(rel(image_path, output_root))}" alt="{html.escape(title)}">
      <figcaption>
        <div class="label">{html.escape(title)}</div>
        <div>{html.escape(human_size(size))}</div>
        <div>{html.escape(extra)}</div>
      </figcaption>
    </figure>
    """


def main() -> int:
    args = parse_args()

    if not features.check("webp"):
        raise SystemExit("This Pillow build does not support WebP encoding.")

    input_path = args.input.resolve()
    output_root = args.output.resolve()
    images = discover_images(input_path, args.recursive)

    if not images:
        raise SystemExit(f"No supported images found in: {input_path}")

    output_root.mkdir(parents=True, exist_ok=True)

    reports = [
        process_image(image_path=image, output_root=output_root, index=index)
        for index, image in enumerate(images, start=1)
    ]

    write_report(reports, output_root)
    write_html(reports, output_root)

    print(f"Processed images: {len(reports)}")
    print(f"Output folder: {output_root}")
    print(f"Report: {output_root / 'report.md'}")
    print(f"HTML comparison: {output_root / 'compare.html'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
