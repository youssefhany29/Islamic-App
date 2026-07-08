from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import tempfile
import time
from pathlib import Path
from zipfile import ZipFile

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
ZIP_PATH = ROOT / "assets" / "quran" / "ligature-basd-svg.zip"
PNG_OUTPUT_DIR = ROOT / "assets" / "quran" / "svg_pages_quran_only"
WEBP_OUTPUT_DIR = ROOT / "assets" / "quran" / "svg_pages_quran_only_webp"
GEOMETRY_OUTPUT_DIR = (
    ROOT / "assets" / "quran" / "svg_geometry_quran_only" / "pages"
)
REPORT_OUTPUT_PATH = (
    ROOT / "assets" / "quran" / "svg_geometry_quran_only" / "generation_report.json"
)
PAGE_METADATA_OUTPUT_PATH = (
    ROOT / "assets" / "quran" / "svg_geometry_quran_only" / "page_metadata.json"
)
QURAN_DATA_PATH = ROOT / "assets" / "hafs_smart_v8.json"
SURAH_CONSTANTS_PATH = (
    ROOT / "lib" / "features" / "quran" / "main_quraan_components" / "constant.dart"
)
PNG_WIDTH = 1300
HORIZONTAL_PADDING = 6.0
VERTICAL_PADDING = 6.0
DEFAULT_PAGES = [1, 2, 3, 56]
ALL_PAGES = list(range(1, 605))
EXTERNAL_NON_QURANIC_SELECTORS = [
    "#md-non-quranic-header-juz-name",
    "#md-non-quranic-header-surah-name",
    "#md-non-quranic-margin-juz-hisb",
    "#md-non-quranic-margin-sajda",
    "#md-non-quranic-margin-sakta",
    "#md-non-quranic-page-number",
]


def load_existing_surah_names() -> dict[int, str]:
    source = SURAH_CONSTANTS_PATH.read_text(encoding="utf-8-sig")
    matches = re.findall(
        r'\{"surah":\s*"(\d+)",\s*"name":\s*"([^"]+)"\}',
        source,
    )
    names = {int(surah): name for surah, name in matches}
    if len(names) != 114:
        raise RuntimeError(
            f"Expected 114 surah names in {SURAH_CONSTANTS_PATH}, found {len(names)}."
        )
    return names


def load_quran_ayah_records() -> list[dict[str, object]]:
    data = json.loads(QURAN_DATA_PATH.read_text(encoding="utf-8-sig"))
    records = data.get("quran")
    if not isinstance(records, list):
        raise RuntimeError(f"Missing quran list in {QURAN_DATA_PATH}.")
    return records


def build_page_metadata() -> dict[str, dict[str, object]]:
    surah_names = load_existing_surah_names()
    quran_records = load_quran_ayah_records()
    records_by_page: dict[int, list[dict[str, object]]] = {
        page: [] for page in ALL_PAGES
    }
    records_by_ayah: dict[tuple[int, int], dict[str, object]] = {}

    for record in quran_records:
        page = int(record["page"])
        surah = int(record["sura_no"])
        ayah = int(record["aya_no"])
        if 1 <= page <= 604:
            records_by_page[page].append(record)
        records_by_ayah[(surah, ayah)] = record

    metadata: dict[str, dict[str, object]] = {}
    for page in ALL_PAGES:
        geometry_path = GEOMETRY_OUTPUT_DIR / f"page_{page:03d}.json"
        if not geometry_path.exists():
            raise RuntimeError(f"Missing geometry for page {page}: {geometry_path}")

        geometry = json.loads(geometry_path.read_text(encoding="utf-8"))
        surah_ids: list[int] = []
        for ayah in geometry.get("ayahs", []):
            surah = int(ayah["surah"])
            if surah not in surah_ids:
                surah_ids.append(surah)

        if not surah_ids:
            for record in records_by_page.get(page, []):
                surah = int(record["sura_no"])
                if surah not in surah_ids:
                    surah_ids.append(surah)

        page_records = sorted(
            records_by_page.get(page, []),
            key=lambda item: int(item.get("id", 0)),
        )
        first_record = page_records[0] if page_records else None
        last_record = page_records[-1] if page_records else None
        first_geometry_ayah = (geometry.get("ayahs") or [None])[0]
        first_lookup = None
        if first_geometry_ayah:
            first_lookup = records_by_ayah.get(
                (
                    int(first_geometry_ayah["surah"]),
                    int(first_geometry_ayah["ayah"]),
                )
            )

        juz_record = first_record or first_lookup
        juz = int(juz_record["jozz"]) if juz_record is not None else 1

        entry: dict[str, object] = {
            "page": page,
            "surahs": [
                {"id": surah, "name": surah_names[surah]} for surah in surah_ids
            ],
            "juz": juz,
        }
        if first_record is not None:
            entry["firstAyah"] = {
                "surah": int(first_record["sura_no"]),
                "ayah": int(first_record["aya_no"]),
            }
        if last_record is not None:
            entry["lastAyah"] = {
                "surah": int(last_record["sura_no"]),
                "ayah": int(last_record["aya_no"]),
            }

        metadata[str(page)] = entry

    return metadata


def write_page_metadata() -> dict[str, dict[str, object]]:
    metadata = build_page_metadata()
    PAGE_METADATA_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    PAGE_METADATA_OUTPUT_PATH.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return metadata


def external_non_quranic_selectors_js() -> str:
    return json.dumps(EXTERNAL_NON_QURANIC_SELECTORS, ensure_ascii=False)


def find_chrome() -> Path:
    candidates = [
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise RuntimeError("Chrome/Edge executable was not found.")


def read_svg(page: int) -> str:
    with ZipFile(ZIP_PATH) as archive:
        return archive.read(f"ligature-basd-svg/{page:03d}.svg").decode(
            "utf-8-sig"
        )


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


def quran_only_geometry_script(page: int) -> str:
    return f"""
(() => {{
  const svg = document.querySelector('svg');
  const viewBox = svg.viewBox.baseVal;
  const externalSelectors = {external_non_quranic_selectors_js()};
  for (const selector of externalSelectors) {{
    for (const el of Array.from(svg.querySelectorAll(selector))) {{
      el.remove();
    }}
  }}

  const contentRoot = svg.querySelector('#md-page-inner') || svg;

  const union = (a, box) => {{
    if (!a) return {{ x: box.x, y: box.y, w: box.width, h: box.height }};
    const left = Math.min(a.x, box.x);
    const top = Math.min(a.y, box.y);
    const right = Math.max(a.x + a.w, box.x + box.width);
    const bottom = Math.max(a.y + a.h, box.y + box.height);
    return {{ x: left, y: top, w: right - left, h: bottom - top }};
  }};

  let content = null;
  for (const el of Array.from(contentRoot.children)) {{
    const box = el.getBBox();
    if (box.width > 0 && box.height > 0) {{
      content = union(content, box);
    }}
  }}
  if (!content) throw new Error('No internal Quran page content found');

  const cropX = Math.max(viewBox.x, content.x - {HORIZONTAL_PADDING});
  const cropY = Math.max(viewBox.y, content.y - {VERTICAL_PADDING});
  const cropRight = Math.min(
    viewBox.x + viewBox.width,
    content.x + content.w + {HORIZONTAL_PADDING}
  );
  const cropBottom = Math.min(
    viewBox.y + viewBox.height,
    content.y + content.h + {VERTICAL_PADDING}
  );
  const crop = {{
    x: cropX,
    y: cropY,
    width: Math.max(1, cropRight - cropX),
    height: Math.max(1, cropBottom - cropY),
    source: 'quran-only',
    horizontalPadding: {HORIZONTAL_PADDING},
    verticalPadding: {VERTICAL_PADDING}
  }};

  const norm = (value, size) => value / size;
  const boxOf = (el) => {{
    const box = el.getBBox();
    return {{
      x: norm(box.x - crop.x, crop.width),
      y: norm(box.y - crop.y, crop.height),
      w: norm(box.width, crop.width),
      h: norm(box.height, crop.height),
      abs: {{
        x: box.x,
        y: box.y,
        w: box.width,
        h: box.height,
        outsideCrop:
          box.x < crop.x ||
          box.y < crop.y ||
          box.x + box.width > crop.x + crop.width ||
          box.y + box.height > crop.y + crop.height
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
    originalViewBox: {{
      x: viewBox.x,
      y: viewBox.y,
      width: viewBox.width,
      height: viewBox.height
    }},
    viewBox: {{ x: crop.x, y: crop.y, width: crop.width, height: crop.height }},
    crop,
    cropRect: {{ x: crop.x, y: crop.y, width: crop.width, height: crop.height }},
    variant: 'quran-only',
    cropSource: '#md-page-inner without external non-quranic groups',
    geometrySelectors: ['[id^="md-word-"]', '[id^="md-aya-mark-"]'],
    removedExternalSelectors: externalSelectors,
    removedNonQuranicExternalOnly: true,
    ayahs: ayahList
  }};
  document.body.innerHTML = `<pre id="geometry-json">${{JSON.stringify(result)}}</pre>`;
}})();
"""


def image_html(svg: str, crop: dict, width: int, height: int) -> str:
    cleaned = re.sub(
        r'viewBox="[^"]+"',
        f'viewBox="{crop["x"]} {crop["y"]} {crop["width"]} {crop["height"]}"',
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
  const externalSelectors = {external_non_quranic_selectors_js()};
  const svg = document.querySelector('svg');
  for (const selector of externalSelectors) {{
    for (const el of Array.from(svg.querySelectorAll(selector))) {{
      el.remove();
    }}
  }}
</script>
</body>
</html>"""


def run_chrome_dump(chrome: Path, html_path: Path, user_data_dir: Path) -> str:
    user_data_dir.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            str(chrome),
            "--headless=new",
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--allow-file-access-from-files",
            f"--user-data-dir={user_data_dir}",
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
    user_data_dir: Path,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    user_data_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            str(chrome),
            "--headless=new",
            "--disable-gpu",
            "--allow-file-access-from-files",
            "--default-background-color=00000000",
            f"--user-data-dir={user_data_dir}",
            f"--window-size={width},{height}",
            f"--screenshot={output}",
            html_path.as_uri(),
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
    for ayah in geometry.get("ayahs", []):
        for box_name, boxes in (
            ("textWords", ayah.get("textWords", [])),
            ("ayahNumberBoxes", ayah.get("ayahNumberBoxes", [])),
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
    return anomalies


def convert_png_to_webp(png_path: Path, webp_path: Path) -> None:
    webp_path.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(png_path) as image:
        image.save(webp_path, "WEBP", lossless=True, exact=True, method=6)


def generate_page(chrome: Path, page: int) -> dict:
    svg = read_svg(page)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        chrome_profile = tmp_path / "chrome-profile"
        geometry_html_path = tmp_path / "geometry.html"
        geometry_html_path.write_text(
            base_html(svg, quran_only_geometry_script(page)),
            encoding="utf-8",
        )
        geometry = round_values(
            extract_json_from_dom(
                run_chrome_dump(chrome, geometry_html_path, chrome_profile)
            )
        )
        crop = geometry["crop"]
        png_height = round(PNG_WIDTH * crop["height"] / crop["width"])
        geometry["outputImageSize"] = {
            "width": PNG_WIDTH,
            "height": png_height,
            "format": "png",
        }

        image_html_path = tmp_path / "image.html"
        image_html_path.write_text(
            image_html(svg, crop, PNG_WIDTH, png_height),
            encoding="utf-8",
        )
        png_output = PNG_OUTPUT_DIR / f"p{page:03d}_quran_only_transparent.png"
        webp_output = WEBP_OUTPUT_DIR / f"p{page:03d}_quran_only_transparent.webp"
        geometry_output = GEOMETRY_OUTPUT_DIR / f"page_{page:03d}.json"
        run_chrome_screenshot(
            chrome,
            image_html_path,
            PNG_WIDTH,
            png_height,
            png_output,
            chrome_profile,
        )
        convert_png_to_webp(png_output, webp_output)

        geometry_output.parent.mkdir(parents=True, exist_ok=True)
        geometry_output.write_text(
            json.dumps(geometry, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    word_count = sum(len(ayah["textWords"]) for ayah in geometry["ayahs"])
    mark_count = sum(len(ayah["ayahNumberBoxes"]) for ayah in geometry["ayahs"])
    return {
        "page": page,
        "png": str(png_output.relative_to(ROOT)).replace("\\", "/"),
        "webp": str(webp_output.relative_to(ROOT)).replace("\\", "/"),
        "geometry": str(geometry_output.relative_to(ROOT)).replace("\\", "/"),
        "imageSize": geometry["outputImageSize"],
        "crop": geometry["crop"],
        "originalViewBox": geometry["originalViewBox"],
        "wordCount": word_count,
        "ayahMarkCount": mark_count,
        "anomalies": validate_geometry(geometry),
    }


def parse_pages(raw_pages: list[str]) -> list[int]:
    pages: list[int] = []
    for raw in raw_pages:
        for part in raw.split(","):
            part = part.strip()
            if not part:
                continue
            page = int(part)
            if page < 1 or page > 604:
                raise ValueError(f"Page must be between 1 and 604: {page}")
            pages.append(page)
    return sorted(set(pages))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate an experimental Quran-only SVG/WebP sample."
    )
    parser.add_argument(
        "--pages",
        nargs="*",
        default=[str(page) for page in DEFAULT_PAGES],
        help="Pages to generate. Accepts spaces or comma-separated values.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generate all 604 Quran pages with the same Quran-only pipeline.",
    )
    parser.add_argument(
        "--metadata-only",
        action="store_true",
        help="Only regenerate page_metadata.json from existing Quran-only geometry.",
    )
    args = parser.parse_args()

    if args.metadata_only:
        metadata = write_page_metadata()
        print(f"metadata={PAGE_METADATA_OUTPUT_PATH} pages={len(metadata)}")
        return 0

    pages = ALL_PAGES if args.all else parse_pages(args.pages)

    started = time.perf_counter()
    chrome = find_chrome()
    generated = [generate_page(chrome, page) for page in pages]
    report = {
        "variant": "quran-only",
        "generatedPages": pages,
        "notes": [
            "Only known external non-Quranic header/footer/margin groups are removed.",
            "Internal surah titles, basmallah, decorations, md-word-*, and md-aya-mark-* remain visible.",
            "Crop and geometry are calculated from the same corrected Quran-only SVG DOM.",
        ],
        "removedExternalSelectors": EXTERNAL_NON_QURANIC_SELECTORS,
        "outputs": generated,
        "elapsedSeconds": round(time.perf_counter() - started, 2),
    }
    REPORT_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_OUTPUT_PATH.write_text(
        json.dumps(round_values(report), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    metadata = write_page_metadata()

    for item in generated:
        print(
            f"page={item['page']:03d} size={item['imageSize']['width']}x{item['imageSize']['height']} "
            f"crop=({item['crop']['x']:.2f},{item['crop']['y']:.2f},"
            f"{item['crop']['width']:.2f},{item['crop']['height']:.2f}) "
            f"words={item['wordCount']} marks={item['ayahMarkCount']} "
            f"anomalies={len(item['anomalies'])}"
        )
    print(f"report={REPORT_OUTPUT_PATH}")
    print(f"metadata={PAGE_METADATA_OUTPUT_PATH} pages={len(metadata)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
