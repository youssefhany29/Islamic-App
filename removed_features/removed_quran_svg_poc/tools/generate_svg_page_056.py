from __future__ import annotations

import html
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[2]
ZIP_PATH = ROOT / "assets" / "quran" / "ligature-basd-svg.zip"
SVG_IN_ZIP = "ligature-basd-svg/056.svg"
PNG_OUTPUT = ROOT / "assets" / "quran" / "svg_pages" / "p056.png"
GEOMETRY_OUTPUT = (
    ROOT / "assets" / "quran" / "svg_geometry" / "page_056_geometry.json"
)
PNG_WIDTH = 1300


def find_chrome() -> Path:
    candidates = [
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise RuntimeError("Chrome/Edge executable was not found.")


def read_svg() -> str:
    with ZipFile(ZIP_PATH) as archive:
        return archive.read(SVG_IN_ZIP).decode("utf-8-sig")


def view_box(svg: str) -> tuple[float, float, float, float]:
    match = re.search(r'viewBox="([^"]+)"', svg)
    if match is None:
        raise RuntimeError("SVG viewBox was not found.")
    values = [float(part) for part in match.group(1).split()]
    if len(values) != 4:
        raise RuntimeError(f"Unexpected viewBox: {match.group(1)}")
    return values[0], values[1], values[2], values[3]


def geometry_html(svg: str) -> str:
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
<script>
(() => {{
  const svg = document.querySelector('svg');
  const viewBox = svg.viewBox.baseVal;
  const norm = (value, size) => value / size;
  const boxOf = (el) => {{
    const box = el.getBBox();
    return {{
      x: norm(box.x - viewBox.x, viewBox.width),
      y: norm(box.y - viewBox.y, viewBox.height),
      w: norm(box.width, viewBox.width),
      h: norm(box.height, viewBox.height),
      abs: {{ x: box.x, y: box.y, w: box.width, h: box.height }}
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
      abs: bbox.abs
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
      abs: bbox.abs
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
        textWords: ayah.textWords.map((word) => ({{
          wordIndex: word.wordIndex,
          line: word.line,
          hafs: word.hafs,
          x: word.x,
          y: word.y,
          w: word.w,
          h: word.h
        }})),
        ayahNumberBoxes: ayah.ayahNumberBoxes.map((box) => ({{
          line: box.line,
          x: box.x,
          y: box.y,
          w: box.w,
          h: box.h
        }}))
      }};
    }});
  const result = {{
    page: 56,
    viewBox: {{ x: viewBox.x, y: viewBox.y, width: viewBox.width, height: viewBox.height }},
    ayahs: ayahList
  }};
  document.body.innerHTML = `<pre id="geometry-json">${{JSON.stringify(result)}}</pre>`;
}})();
</script>
</body>
</html>"""


def image_html(svg: str, width: int, height: int) -> str:
    svg = re.sub(r"<svg\b", f'<svg width="{width}" height="{height}"', svg, count=1)
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    html, body {{ margin: 0; padding: 0; width: {width}px; height: {height}px; overflow: hidden; background: white; }}
    svg {{ display: block; width: {width}px; height: {height}px; }}
  </style>
</head>
<body>{svg}</body>
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


def run_chrome_screenshot(chrome: Path, html_path: Path, width: int, height: int) -> None:
    PNG_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            str(chrome),
            "--headless=new",
            "--disable-gpu",
            "--allow-file-access-from-files",
            f"--window-size={width},{height}",
            f"--screenshot={PNG_OUTPUT}",
            html_path.as_uri(),
        ],
        check=True,
    )


def extract_json_from_dom(dom: str) -> dict:
    match = re.search(r'<pre id="geometry-json">(.+?)</pre>', dom, re.S)
    if match is None:
        raise RuntimeError("geometry-json element was not found in Chrome dump.")
    return json.loads(html.unescape(match.group(1)))


def rounded_geometry(data: dict) -> dict:
    def round_value(value):
        if isinstance(value, float):
            return round(value, 8)
        if isinstance(value, list):
            return [round_value(item) for item in value]
        if isinstance(value, dict):
            return {key: round_value(item) for key, item in value.items()}
        return value

    return round_value(data)


def main() -> int:
    svg = read_svg()
    _, _, width, height = view_box(svg)
    png_height = round(PNG_WIDTH * height / width)
    chrome = find_chrome()

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        geometry_html_path = tmp_path / "geometry.html"
        image_html_path = tmp_path / "image.html"
        geometry_html_path.write_text(geometry_html(svg), encoding="utf-8")
        image_html_path.write_text(
            image_html(svg, PNG_WIDTH, png_height),
            encoding="utf-8",
        )

        dom = run_chrome_dump(chrome, geometry_html_path)
        geometry = rounded_geometry(extract_json_from_dom(dom))
        GEOMETRY_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        GEOMETRY_OUTPUT.write_text(
            json.dumps(geometry, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        run_chrome_screenshot(chrome, image_html_path, PNG_WIDTH, png_height)

    word_count = sum(len(ayah["textWords"]) for ayah in geometry["ayahs"])
    mark_count = sum(len(ayah["ayahNumberBoxes"]) for ayah in geometry["ayahs"])
    print(f"SVG page 56 PNG: {PNG_OUTPUT}")
    print(f"SVG page 56 geometry: {GEOMETRY_OUTPUT}")
    print(f"PNG size: {PNG_WIDTH}x{png_height}")
    print(f"Ayahs: {len(geometry['ayahs'])}, words: {word_count}, aya marks: {mark_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
