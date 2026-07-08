from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "assets" / "quran" / "svg_pages"
OUTPUT_ROOT = ROOT / "assets" / "quran" / "svg_pages_webp_test"
REPORT_PATH = OUTPUT_ROOT / "webp_compression_report.json"

PAGES = [1, 2, 3, 56, 120, 255, 333, 480, 589, 604]
QUALITIES = [95, 90, 85]


def png_path(page: int) -> Path:
    return SOURCE_DIR / f"p{page:03d}_no_hizb_cropped_transparent.png"


def webp_path(page: int, quality: int) -> Path:
    return OUTPUT_ROOT / f"q{quality}" / f"p{page:03d}.webp"


def alpha_info(path: Path) -> dict[str, object]:
    with Image.open(path) as image:
        converted = image.convert("RGBA")
        alpha = converted.getchannel("A")
        extrema = alpha.getextrema()
        pixels = alpha.getdata()
        transparent = 0
        partial = 0
        opaque = 0
        for value in pixels:
            if value == 0:
                transparent += 1
            elif value == 255:
                opaque += 1
            else:
                partial += 1
        return {
            "mode": image.mode,
            "size": list(image.size),
            "alphaExtrema": list(extrema),
            "transparentPixels": transparent,
            "partialAlphaPixels": partial,
            "opaquePixels": opaque,
        }


def rmse_rgb(a_path: Path, b_path: Path) -> float:
    with Image.open(a_path) as a_image, Image.open(b_path) as b_image:
        a = a_image.convert("RGBA")
        b = b_image.convert("RGBA")
        if a.size != b.size:
            raise RuntimeError(f"Size mismatch: {a_path} vs {b_path}")
        a_pixels = a.getdata()
        b_pixels = b.getdata()
        total = 0
        count = 0
        for a_pixel, b_pixel in zip(a_pixels, b_pixels):
            if a_pixel[3] == 0 and b_pixel[3] == 0:
                continue
            for index in range(3):
                delta = a_pixel[index] - b_pixel[index]
                total += delta * delta
                count += 1
        return math.sqrt(total / count) if count else 0.0


def main() -> int:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    source_total = 0
    page_reports: list[dict[str, object]] = []
    quality_reports: dict[str, dict[str, object]] = {}

    for page in PAGES:
        source = png_path(page)
        if not source.exists():
            raise FileNotFoundError(source)
        source_size = source.stat().st_size
        source_total += source_size
        page_reports.append(
            {
                "page": page,
                "pngBytes": source_size,
                "pngAlpha": alpha_info(source),
            }
        )

    for quality in QUALITIES:
        output_dir = OUTPUT_ROOT / f"q{quality}"
        output_dir.mkdir(parents=True, exist_ok=True)
        files: list[dict[str, object]] = []

        for page in PAGES:
            source = png_path(page)
            output = webp_path(page, quality)
            with Image.open(source) as image:
                image.save(
                    output,
                    "WEBP",
                    quality=quality,
                    method=6,
                    lossless=False,
                    exact=True,
                )

            webp_size = output.stat().st_size
            png_size = source.stat().st_size
            files.append(
                {
                    "page": page,
                    "path": str(output.relative_to(ROOT)).replace("\\", "/"),
                    "pngBytes": png_size,
                    "webpBytes": webp_size,
                    "savingPercent": round((1 - webp_size / png_size) * 100, 2),
                    "webpAlpha": alpha_info(output),
                    "rmseRgbVisiblePixels": round(rmse_rgb(source, output), 4),
                }
            )

        sizes = [int(item["webpBytes"]) for item in files]
        total = sum(sizes)
        quality_reports[f"q{quality}"] = {
            "totalBytes": total,
            "averageBytes": round(total / len(files), 2),
            "minBytes": min(sizes),
            "maxBytes": max(sizes),
            "savingPercentVsPng": round((1 - total / source_total) * 100, 2),
            "files": files,
        }

    report = {
        "pages": PAGES,
        "qualities": QUALITIES,
        "sourcePngTotalBytes": source_total,
        "sourcePages": page_reports,
        "webp": quality_reports,
    }
    REPORT_PATH.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
