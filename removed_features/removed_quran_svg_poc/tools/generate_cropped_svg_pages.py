from __future__ import annotations

import html
import json
import re
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[2]
ZIP_PATH = ROOT / "assets" / "quran" / "ligature-basd-svg.zip"
OVERRIDES_PATH = ROOT / "assets" / "quran" / "svg_crop_overrides.json"
PAGES = range(1, 605)
PNG_WIDTH = 1300
HORIZONTAL_PADDING = 8.0
IMAGE_OUTPUT_DIR = ROOT / "assets" / "quran" / "svg_pages"
GEOMETRY_OUTPUT_DIR = ROOT / "assets" / "quran" / "svg_geometry" / "pages"
REPORT_OUTPUT_PATH = ROOT / "assets" / "quran" / "svg_geometry" / "svg_generation_report.json"


def find_chrome() -> Path:
    candidates = [
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise RuntimeError("Chrome/Edge executable was not found.")


def find_cwebp() -> Path | None:
    cwebp = shutil.which("cwebp")
    return Path(cwebp) if cwebp else None


def read_svg(page: int) -> str:
    with ZipFile(ZIP_PATH) as archive:
        return archive.read(f"ligature-basd-svg/{page:03d}.svg").decode(
            "utf-8-sig"
        )


def load_overrides() -> dict[str, dict[str, float]]:
    if not OVERRIDES_PATH.exists():
        return {}
    return json.loads(OVERRIDES_PATH.read_text(encoding="utf-8"))


def view_box(svg: str) -> tuple[float, float, float, float]:
    match = re.search(r'viewBox="([^"]+)"', svg)
    if match is None:
        raise RuntimeError("SVG viewBox was not found.")
    values = [float(part) for part in match.group(1).split()]
    if len(values) != 4:
        raise RuntimeError(f"Unexpected viewBox: {match.group(1)}")
    return values[0], values[1], values[2], values[3]


def base_html(svg: str, script: str) -> str:
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    html, body {{ margin: 0; padding: 0; background: white; }}
    svg {{ display: block; }}
  </style>
</head>
<body>
{svg}
<script>{script}</script>
</body>
</html>"""


def crop_and_geometry_script(
    page: int,
    left_override: float,
    right_override: float,
) -> str:
    return f"""
(() => {{
  const svg = document.querySelector('svg');
  const viewBox = svg.viewBox.baseVal;
  const margin = svg.querySelector('#md-non-quranic-margin-juz-hisb');
  if (margin) margin.remove();

  const selectors = [
    '#md-page-inner',
    '#md-non-quranic-header-juz-name',
    '#md-non-quranic-header-surah-name',
    '#md-non-quranic-page-number',
    '[id^="md-word-"]',
    '[id^="md-aya-mark-"]',
    '[id^="md-non-quranic-"]:not(#md-non-quranic-margin-juz-hisb)'
  ];
  const cropElements = Array.from(svg.querySelectorAll(selectors.join(',')))
    .filter((el) => el.id !== 'md-page-inner' || el.getBBox().width > 0);
  const union = (a, b) => {{
    if (!a) return {{ x: b.x, y: b.y, w: b.width, h: b.height }};
    const left = Math.min(a.x, b.x);
    const top = Math.min(a.y, b.y);
    const right = Math.max(a.x + a.w, b.x + b.width);
    const bottom = Math.max(a.y + a.h, b.y + b.height);
    return {{ x: left, y: top, w: right - left, h: bottom - top }};
  }};
  let content = null;
  for (const el of cropElements) {{
    content = union(content, el.getBBox());
  }}
  if (!content) throw new Error('No crop content found');

  const autoCropX = Math.max(viewBox.x, content.x - {HORIZONTAL_PADDING});
  const autoCropRight = Math.min(viewBox.x + viewBox.width, content.x + content.w + {HORIZONTAL_PADDING});
  const cropX = Math.max(viewBox.x, autoCropX + {left_override});
  const cropRight = Math.min(viewBox.x + viewBox.width, autoCropRight + {right_override});
  const cropWidth = Math.max(1, cropRight - cropX);
  const crop = {{
    x: cropX,
    y: viewBox.y,
    width: cropWidth,
    height: viewBox.height,
    autoX: autoCropX,
    autoRight: autoCropRight,
    autoWidth: autoCropRight - autoCropX,
    leftOverride: {left_override},
    rightOverride: {right_override},
    horizontalPadding: {HORIZONTAL_PADDING}
  }};

  const norm = (value, size) => value / size;
  const boxOf = (el) => {{
    const box = el.getBBox();
    return {{
      x: norm(box.x - crop.x, crop.width),
      y: norm(box.y - viewBox.y, viewBox.height),
      w: norm(box.width, crop.width),
      h: norm(box.height, viewBox.height),
      abs: {{
        x: box.x,
        y: box.y,
        w: box.width,
        h: box.height,
        outsideCrop: box.x < crop.x || box.x + box.width > crop.x + crop.width
      }}
    }};
  }};
  const keyOf = (surah, ayah) => `${{Number(surah)}}:${{Number(ayah)}}`;
  const ayahs = new Map();
  const ensureAyah = (surah, ayah) => {{
    const key = keyOf(surah, ayah);
    if (!ayahs.has(key)) {{
      ayahs.set(key, {{
        surah: Number(surah),
        ayah: Number(ayah),
        segmentsByLine: new Map(),
        textWords: [],
        ayahNumberBoxes: []
      }});
    }}
    return ayahs.get(key);
  }};
  const expand = (a, b) => {{
    if (!a) return {{ ...b }};
    const left = Math.min(a.x, b.x);
    const top = Math.min(a.y, b.y);
    const right = Math.max(a.x + a.w, b.x + b.w);
    const bottom = Math.max(a.y + a.h, b.y + b.h);
    return {{ x: left, y: top, w: right - left, h: bottom - top }};
  }};

  for (const el of svg.querySelectorAll('[id^="md-word-"]')) {{
    const surah = el.dataset.surah;
    const ayah = el.dataset.aya;
    const line = Number(el.dataset.lineNumber);
    const bbox = boxOf(el);
    const word = {{
      wordIndex: Number(el.dataset.wordIndexInAyah),
      line,
      hafs: el.dataset.hafs || '',
      x: bbox.x,
      y: bbox.y,
      w: bbox.w,
      h: bbox.h,
      outsideCrop: bbox.abs.outsideCrop
    }};
    const ayahModel = ensureAyah(surah, ayah);
    ayahModel.textWords.push(word);
    const current = ayahModel.segmentsByLine.get(line);
    ayahModel.segmentsByLine.set(line, expand(current, bbox));
  }}
  for (const el of svg.querySelectorAll('[id^="md-aya-mark-"]')) {{
    const surah = el.dataset.surah;
    const ayah = el.dataset.aya;
    const line = Number(el.dataset.lineNumber);
    const bbox = boxOf(el);
    ensureAyah(surah, ayah).ayahNumberBoxes.push({{
      line,
      x: bbox.x,
      y: bbox.y,
      w: bbox.w,
      h: bbox.h,
      outsideCrop: bbox.abs.outsideCrop
    }});
  }}
  const ayahList = Array.from(ayahs.values())
    .sort((a, b) => a.surah - b.surah || a.ayah - b.ayah)
    .map((ayah) => {{
      ayah.textWords.sort((a, b) => a.wordIndex - b.wordIndex);
      ayah.ayahNumberBoxes.sort((a, b) => a.line - b.line || a.x - b.x);
      const segments = Array.from(ayah.segmentsByLine.entries())
        .sort((a, b) => a[0] - b[0])
        .map(([line, rect]) => ({{ line, x: rect.x, y: rect.y, w: rect.w, h: rect.h }}));
      return {{
        surah: ayah.surah,
        ayah: ayah.ayah,
        segments,
        textWords: ayah.textWords,
        ayahNumberBoxes: ayah.ayahNumberBoxes
      }};
    }});
  const result = {{
    page: {page},
    originalViewBox: {{ x: viewBox.x, y: viewBox.y, width: viewBox.width, height: viewBox.height }},
    viewBox: {{ x: viewBox.x, y: viewBox.y, width: viewBox.width, height: viewBox.height }},
    crop,
    cropRect: {{ x: crop.x, y: crop.y, width: crop.width, height: crop.height }},
    removed: ['md-non-quranic-margin-juz-hisb'],
    ayahs: ayahList
  }};
  document.body.innerHTML = `<pre id="geometry-json">${{JSON.stringify(result)}}</pre>`;
}})();
"""


def image_html(
    svg: str,
    crop: dict,
    width: int,
    height: int,
) -> str:
    cleaned = re.sub(
        r'viewBox="[^"]+"',
        f'viewBox="{crop["x"]} 0 {crop["width"]} {crop["height"]}"',
        svg,
        count=1,
    )
    cleaned = re.sub(
        r"<svg\b",
        f'<svg width="{width}" height="{height}"',
        cleaned,
        count=1,
    )
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    html, body {{ margin: 0; padding: 0; width: {width}px; height: {height}px; overflow: hidden; background: transparent; }}
    svg {{ display: block; width: {width}px; height: {height}px; }}
  </style>
</head>
<body>{cleaned}
<script>
  const margin = document.querySelector('#md-non-quranic-margin-juz-hisb');
  if (margin) margin.remove();
</script>
</body>
</html>"""


def run_chrome_dump(chrome: Path, html_path: Path) -> str:
    result = subprocess.run(
        [
            str(chrome),
            "--headless=new",
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--allow-file-access-from-files",
            "--dump-dom",
            html_path.as_uri(),
        ],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return result.stdout


def run_chrome_screenshot(
    chrome: Path,
    html_path: Path,
    width: int,
    height: int,
    output: Path,
    transparent: bool = False,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(chrome),
        "--headless=new",
        "--disable-gpu",
        "--allow-file-access-from-files",
        f"--window-size={width},{height}",
        f"--screenshot={output}",
    ]
    if transparent:
        command.append("--default-background-color=00000000")
    command.append(html_path.as_uri())
    subprocess.run(
        command,
        check=True,
    )


def convert_to_webp(cwebp: Path, png_path: Path, webp_path: Path) -> None:
    subprocess.run(
        [
            str(cwebp),
            "-quiet",
            "-q",
            "95",
            str(png_path),
            "-o",
            str(webp_path),
        ],
        check=True,
    )


def extract_json_from_dom(dom: str) -> dict:
    match = re.search(r'<pre id="geometry-json">(.+?)</pre>', dom, re.S)
    if match is None:
        raise RuntimeError("geometry-json element was not found in Chrome dump.")
    return json.loads(html.unescape(match.group(1)))


def round_values(data):
    if isinstance(data, float):
        return round(data, 8)
    if isinstance(data, list):
        return [round_values(item) for item in data]
    if isinstance(data, dict):
        return {key: round_values(value) for key, value in data.items()}
    return data


def validate_geometry(geometry: dict) -> list[dict[str, object]]:
    anomalies: list[dict[str, object]] = []
    page = geometry["page"]
    ayahs = geometry.get("ayahs", [])
    if not ayahs:
        anomalies.append({"page": page, "type": "page_without_ayahs"})

    word_count = 0
    mark_count = 0
    for ayah in ayahs:
        text_words = ayah.get("textWords", [])
        number_boxes = ayah.get("ayahNumberBoxes", [])
        word_count += len(text_words)
        mark_count += len(number_boxes)
        if not text_words:
            anomalies.append(
                {
                    "page": page,
                    "type": "ayah_without_textWords",
                    "surah": ayah.get("surah"),
                    "ayah": ayah.get("ayah"),
                }
            )
        if not number_boxes:
            anomalies.append(
                {
                    "page": page,
                    "type": "ayah_without_ayahNumberBoxes",
                    "surah": ayah.get("surah"),
                    "ayah": ayah.get("ayah"),
                }
            )
        for box_name, boxes in (
            ("textWords", text_words),
            ("ayahNumberBoxes", number_boxes),
            ("segments", ayah.get("segments", [])),
        ):
            for box in boxes:
                if (
                    box.get("x", 0) < -0.0001
                    or box.get("y", 0) < -0.0001
                    or box.get("x", 0) + box.get("w", 0) > 1.0001
                    or box.get("y", 0) + box.get("h", 0) > 1.0001
                    or box.get("outsideCrop") is True
                ):
                    anomalies.append(
                        {
                            "page": page,
                            "type": "box_outside_crop",
                            "box": box_name,
                            "surah": ayah.get("surah"),
                            "ayah": ayah.get("ayah"),
                            "line": box.get("line"),
                        }
                    )

    if word_count == 0:
        anomalies.append({"page": page, "type": "page_without_words"})
    if mark_count == 0:
        anomalies.append({"page": page, "type": "page_without_aya_marks"})
    return anomalies


def dir_size(path: Path, pattern: str) -> int:
    if not path.exists():
        return 0
    return sum(file.stat().st_size for file in path.glob(pattern) if file.is_file())


def main() -> int:
    started = time.perf_counter()
    chrome = find_chrome()
    cwebp = find_cwebp()
    overrides = load_overrides()
    generated_pages: list[int] = []
    missing_pages: list[int] = []
    anomalies: list[dict[str, object]] = []
    crop_by_page: dict[str, dict[str, float]] = {}
    image_format = "png"
    webp_generated = False

    for page in PAGES:
        try:
            svg = read_svg(page)
        except KeyError:
            missing_pages.append(page)
            print(f"page={page} missing SVG")
            continue

        _, _, original_width, original_height = view_box(svg)
        page_overrides = overrides.get(str(page), {})
        left_override = float(page_overrides.get("left", 0))
        right_override = float(page_overrides.get("right", 0))

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            geometry_html_path = tmp_path / "geometry.html"
            geometry_html_path.write_text(
                base_html(svg, crop_and_geometry_script(page, left_override, right_override)),
                encoding="utf-8",
            )
            dom = run_chrome_dump(chrome, geometry_html_path)
            geometry = round_values(extract_json_from_dom(dom))

            crop = geometry["crop"]
            png_height = round(PNG_WIDTH * crop["height"] / crop["width"])
            transparent_html_path = tmp_path / "image_transparent.html"
            transparent_html_path.write_text(
                image_html(svg, crop, PNG_WIDTH, png_height),
                encoding="utf-8",
            )

            geometry["outputImageSize"] = {
                "width": PNG_WIDTH,
                "height": png_height,
                "format": image_format,
            }
            transparent_output = (
                IMAGE_OUTPUT_DIR / f"p{page:03d}_no_hizb_cropped_transparent.png"
            )
            geometry_output = GEOMETRY_OUTPUT_DIR / f"page_{page:03d}.json"
            run_chrome_screenshot(
                chrome,
                transparent_html_path,
                PNG_WIDTH,
                png_height,
                transparent_output,
                transparent=True,
            )

            if cwebp is not None:
                transparent_webp_output = (
                    IMAGE_OUTPUT_DIR / f"p{page:03d}_no_hizb_cropped_transparent.webp"
                )
                convert_to_webp(cwebp, transparent_output, transparent_webp_output)
                webp_generated = True

            geometry_output.parent.mkdir(parents=True, exist_ok=True)
            geometry_output.write_text(
                json.dumps(geometry, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

        generated_pages.append(page)
        anomalies.extend(validate_geometry(geometry))
        crop_by_page[str(page)] = {
            "cropX": geometry["crop"]["x"],
            "cropWidth": geometry["crop"]["width"],
            "autoX": geometry["crop"]["autoX"],
            "autoWidth": geometry["crop"]["autoWidth"],
            "leftOverride": left_override,
            "rightOverride": right_override,
        }
        word_count = sum(len(ayah["textWords"]) for ayah in geometry["ayahs"])
        mark_count = sum(len(ayah["ayahNumberBoxes"]) for ayah in geometry["ayahs"])
        print(
            f"page={page} transparent={transparent_output.name} "
            f"size={PNG_WIDTH}x{png_height} "
            f"cropX={geometry['crop']['x']:.2f} cropWidth={geometry['crop']['width']:.2f} "
            f"words={word_count} marks={mark_count} overrides=({left_override},{right_override})"
        )

    elapsed = time.perf_counter() - started
    page_without_words = sorted(
        {
            int(item["page"])
            for item in anomalies
            if item["type"] == "page_without_words"
        }
    )
    page_without_marks = sorted(
        {
            int(item["page"])
            for item in anomalies
            if item["type"] == "page_without_aya_marks"
        }
    )
    report = {
        "totalPagesGenerated": len(generated_pages),
        "generatedPages": generated_pages,
        "missingPages": missing_pages,
        "pagesWithoutWords": page_without_words,
        "pagesWithoutAyaMarks": page_without_marks,
        "boxesOutsideCrop": sum(
            1 for item in anomalies if item["type"] == "box_outside_crop"
        ),
        "ayahsWithoutTextWords": sum(
            1 for item in anomalies if item["type"] == "ayah_without_textWords"
        ),
        "ayahsWithoutAyahNumberBoxes": sum(
            1
            for item in anomalies
            if item["type"] == "ayah_without_ayahNumberBoxes"
        ),
        "imageFormat": image_format,
        "transparentWebpGenerated": webp_generated,
        "imageTotalSizeBytes": dir_size(
            IMAGE_OUTPUT_DIR,
            f"*_no_hizb_cropped_transparent.{image_format}",
        ),
        "geometryTotalSizeBytes": dir_size(GEOMETRY_OUTPUT_DIR, "*.json"),
        "cropByPage": crop_by_page,
        "elapsedSeconds": round(elapsed, 2),
        "anomalies": anomalies,
    }
    REPORT_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_OUTPUT_PATH.write_text(
        json.dumps(round_values(report), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(
        "summary "
        f"generated={report['totalPagesGenerated']} missing={len(missing_pages)} "
        f"imageFormat={image_format} imageBytes={report['imageTotalSizeBytes']} "
        f"geometryBytes={report['geometryTotalSizeBytes']} "
        f"anomalies={len(anomalies)} elapsed={report['elapsedSeconds']}s "
        f"report={REPORT_OUTPUT_PATH}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
