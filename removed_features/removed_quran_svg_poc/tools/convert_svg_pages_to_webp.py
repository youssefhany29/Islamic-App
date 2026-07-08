from __future__ import annotations

import json
import time
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "assets" / "quran" / "svg_pages"
OUTPUT_DIR = ROOT / "assets" / "quran" / "svg_pages_webp"
REPORT_PATH = OUTPUT_DIR / "webp_conversion_report.json"

PAGES = range(1, 605)
QUALITY = 95
VALIDATION_SAMPLE = [1, 2, 3, 56, 120, 255, 333, 480, 589, 604]


def png_path(page: int) -> Path:
    return SOURCE_DIR / f"p{page:03d}_no_hizb_cropped_transparent.png"


def webp_path(page: int) -> Path:
    return OUTPUT_DIR / f"p{page:03d}_no_hizb_cropped_transparent.webp"


def alpha_info(path: Path) -> dict[str, object]:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        alpha = rgba.getchannel("A")
        extrema = alpha.getextrema()
        transparent = 0
        partial = 0
        opaque = 0
        for value in alpha.getdata():
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


def exact_rgba_match(a_path: Path, b_path: Path) -> bool:
    with Image.open(a_path) as a_image, Image.open(b_path) as b_image:
        a = a_image.convert("RGBA")
        b = b_image.convert("RGBA")
        if a.size != b.size:
            return False
        diff = ImageChops.difference(a, b)
        return all(extrema == (0, 0) for extrema in diff.getextrema())


def main() -> int:
    started = time.perf_counter()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    converted: list[int] = []
    missing_inputs: list[int] = []
    failed_conversions: list[dict[str, object]] = []
    files: list[dict[str, object]] = []
    png_total = 0
    webp_total = 0

    for page in PAGES:
        source = png_path(page)
        output = webp_path(page)
        if not source.exists():
            missing_inputs.append(page)
            continue

        try:
            with Image.open(source) as image:
                image.save(
                    output,
                    "WEBP",
                    quality=QUALITY,
                    method=6,
                    lossless=True,
                    exact=True,
                )
        except Exception as exc:
            failed_conversions.append({"page": page, "error": str(exc)})
            continue

        png_size = source.stat().st_size
        webp_size = output.stat().st_size
        png_total += png_size
        webp_total += webp_size
        converted.append(page)
        files.append(
            {
                "page": page,
                "pngBytes": png_size,
                "webpBytes": webp_size,
                "savingPercent": round((1 - webp_size / png_size) * 100, 2),
                "path": str(output.relative_to(ROOT)).replace("\\", "/"),
            }
        )

        print(
            f"page={page:03d} png={png_size} webp={webp_size} "
            f"saving={files[-1]['savingPercent']}%"
        )

    alpha_validation = []
    exact_rgba_validation = []
    for page in VALIDATION_SAMPLE:
        source = png_path(page)
        output = webp_path(page)
        if not source.exists() or not output.exists():
            alpha_validation.append(
                {
                    "page": page,
                    "available": False,
                }
            )
            exact_rgba_validation.append(
                {
                    "page": page,
                    "available": False,
                    "exactRgba": False,
                }
            )
            continue

        alpha_validation.append(
            {
                "page": page,
                "available": True,
                "pngAlpha": alpha_info(source),
                "webpAlpha": alpha_info(output),
            }
        )
        exact_rgba_validation.append(
            {
                "page": page,
                "available": True,
                "exactRgba": exact_rgba_match(source, output),
            }
        )

    sorted_by_size = sorted(files, key=lambda item: int(item["webpBytes"]))
    report = {
        "quality": QUALITY,
        "lossless": True,
        "exact": True,
        "note": (
            "WebP is written with lossless=True and exact=True. "
            "That is why the validation sample can decode back to exact RGBA; "
            "quality=95 is kept as the requested quality setting but lossless "
            "controls the pixel-preserving result."
        ),
        "totalConverted": len(converted),
        "missingInputs": missing_inputs,
        "failedConversions": failed_conversions,
        "totalPngBytes": png_total,
        "totalWebpBytes": webp_total,
        "savingPercent": round((1 - webp_total / png_total) * 100, 2)
        if png_total
        else 0,
        "alphaValidationSample": alpha_validation,
        "exactRgbaComparisonSample": exact_rgba_validation,
        "smallestWebpPages": sorted_by_size[:10],
        "largestWebpPages": sorted_by_size[-10:],
        "elapsedSeconds": round(time.perf_counter() - started, 2),
    }
    REPORT_PATH.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(
        "summary "
        f"converted={report['totalConverted']} missing={len(missing_inputs)} "
        f"failed={len(failed_conversions)} png={png_total} webp={webp_total} "
        f"saving={report['savingPercent']}% elapsed={report['elapsedSeconds']}s"
    )
    return 0 if not failed_conversions and not missing_inputs else 1


if __name__ == "__main__":
    raise SystemExit(main())
