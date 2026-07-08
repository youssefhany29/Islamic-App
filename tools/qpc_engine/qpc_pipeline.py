import argparse
import gzip
import json
import re
import sqlite3
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont


QURAN_FOUNDATION_WOFF2_BASE = (
    "https://verses.quran.foundation/fonts/quran/hafs/v4/ot-svg"
)


@dataclass(frozen=True)
class LayoutLine:
    page_number: int
    line_number: int
    line_type: str
    is_centered: bool
    first_word_id: Optional[int]
    last_word_id: Optional[int]
    surah_number: Optional[int]


@dataclass(frozen=True)
class QuranWord:
    id: int
    surah: int
    ayah: int
    word: int
    location: str
    text: str


def format_kb(size: int) -> str:
    return f"{size / 1024:.2f} KB"


def format_mb(size: int) -> str:
    return f"{size / (1024 * 1024):.2f} MB"


def as_optional_int(value: Any) -> Optional[int]:
    if value is None:
        return None

    text = str(value).strip()

    if text == "":
        return None

    try:
        return int(text)
    except ValueError:
        return None


def parse_pages(value: str) -> List[int]:
    text = value.strip()

    if text.lower() == "all":
        return list(range(1, 605))

    pages: List[int] = []

    for part in text.split(","):
        part = part.strip()

        if not part:
            continue

        if "-" in part:
            start_text, end_text = part.split("-", 1)
            start = int(start_text.strip())
            end = int(end_text.strip())

            if start > end:
                start, end = end, start

            pages.extend(range(start, end + 1))
        else:
            pages.append(int(part))

    cleaned = sorted(set(page for page in pages if 1 <= page <= 604))

    if not cleaned:
        raise ValueError("No valid pages selected. Use all, 1-20, or 1,100,604.")

    return cleaned


def normalize_svg_text(text: str) -> str:
    text = text.strip()
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    text = re.sub(r">\s+<", "><", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def compact_svg(svg_text: str) -> Dict[str, Optional[str]]:
    text = normalize_svg_text(svg_text)

    view_box_match = re.search(
        r"""viewBox\s*=\s*["']([^"']+)["']""",
        text,
        flags=re.IGNORECASE,
    )

    view_box = view_box_match.group(1).strip() if view_box_match else None

    body = re.sub(r"^.*?<svg[^>]*>", "", text, flags=re.IGNORECASE | re.DOTALL)
    body = re.sub(r"</svg>\s*$", "", body, flags=re.IGNORECASE | re.DOTALL)
    body = normalize_svg_text(body)

    body = re.sub(r"""\s+id=["'][^"']*["']""", "", body)
    body = re.sub(r"""\s+class=["'][^"']*["']""", "", body)

    return {
        "vb": view_box,
        "b": body,
    }


def load_words_by_id(words_json_path: Path) -> Dict[int, QuranWord]:
    if not words_json_path.exists():
        raise FileNotFoundError(words_json_path)

    with words_json_path.open("r", encoding="utf-8") as file:
        raw_data = json.load(file)

    words_by_id: Dict[int, QuranWord] = {}

    for value in raw_data.values():
        word_id = int(value["id"])

        words_by_id[word_id] = QuranWord(
            id=word_id,
            surah=int(value["surah"]),
            ayah=int(value["ayah"]),
            word=int(value["word"]),
            location=str(value["location"]),
            text=str(value["text"]),
        )

    return words_by_id


def load_all_layout_lines(layout_db_path: Path) -> Dict[int, List[LayoutLine]]:
    if not layout_db_path.exists():
        raise FileNotFoundError(layout_db_path)

    connection = sqlite3.connect(str(layout_db_path))
    connection.row_factory = sqlite3.Row

    try:
        rows = connection.execute(
            """
            SELECT
              page_number,
              line_number,
              line_type,
              is_centered,
              first_word_id,
              last_word_id,
              surah_number
            FROM pages
            ORDER BY page_number ASC, line_number ASC
            """
        ).fetchall()
    finally:
        connection.close()

    lines_by_page: Dict[int, List[LayoutLine]] = {}

    for row in rows:
        page_number = int(row["page_number"])

        lines_by_page.setdefault(page_number, []).append(
            LayoutLine(
                page_number=page_number,
                line_number=int(row["line_number"]),
                line_type=str(row["line_type"]),
                is_centered=as_optional_int(row["is_centered"]) == 1,
                first_word_id=as_optional_int(row["first_word_id"]),
                last_word_id=as_optional_int(row["last_word_id"]),
                surah_number=as_optional_int(row["surah_number"]),
            )
        )

    return lines_by_page


def download_woff2_if_needed(
    *,
    page: int,
    theme: str,
    woff2_dir: Path,
) -> Path:
    output_path = woff2_dir / theme / f"p{page}.woff2"

    if output_path.exists() and output_path.stat().st_size > 0:
        return output_path

    output_path.parent.mkdir(parents=True, exist_ok=True)

    url = f"{QURAN_FOUNDATION_WOFF2_BASE}/{theme}/woff2/p{page}.woff2"

    request = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0"},
    )

    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()

    output_path.write_bytes(data)

    return output_path


def get_svg_docs(font: TTFont) -> List[Any]:
    svg_table = font["SVG "]

    docs = getattr(svg_table, "docList", None)

    if docs is None:
        docs = getattr(svg_table, "svgDocList", None)

    if docs is None:
        raise RuntimeError("SVG docs not found in font.")

    return docs


def build_compact_svg_from_glyf(
    font: TTFont,
    glyph_name: str,
) -> Optional[Dict[str, Optional[str]]]:
    glyph_set = font.getGlyphSet()

    if glyph_name not in glyph_set:
        return None

    glyph = glyph_set[glyph_name]

    path_pen = SVGPathPen(glyph_set)

    try:
        glyph.draw(path_pen)
    except Exception:
        return None

    path_data = path_pen.getCommands()

    if not path_data:
        return None

    units_per_em = int(font["head"].unitsPerEm)

    bounds_pen = BoundsPen(glyph_set)

    try:
        glyph.draw(bounds_pen)
    except Exception:
        bounds_pen.bounds = None

    if bounds_pen.bounds is not None:
        x_min, y_min, x_max, y_max = bounds_pen.bounds
        width = max(1.0, float(x_max - x_min))
        height = max(1.0, float(y_max - y_min))
        view_box_x = float(x_min)
        view_box_y = float(units_per_em - y_max)
        view_box = f"{view_box_x:g} {view_box_y:g} {width:g} {height:g}"
    else:
        view_box = f"0 0 {units_per_em} {units_per_em}"

    body = (
        f'<path d="{path_data}" '
        f'transform="matrix(1 0 0 -1 0 {units_per_em})"/>'
    )

    return {
        "vb": view_box,
        "b": body,
    }


def build_svg_doc_maps(font: TTFont) -> Dict[str, Any]:
    docs = get_svg_docs(font)
    glyph_order = font.getGlyphOrder()
    cmap = font.getBestCmap()

    glyph_name_to_codepoints: Dict[str, List[int]] = {}

    for codepoint, glyph_name in cmap.items():
        glyph_name_to_codepoints.setdefault(glyph_name, []).append(codepoint)

    svg_docs: List[Dict[str, Optional[str]]] = []
    codepoint_to_svg_index: Dict[int, int] = {}
    glyf_fallback_codepoints: Dict[int, int] = {}

    for item in docs:
        if len(item) < 3:
            continue

        svg_doc = item[0]
        start_gid = int(item[1])
        end_gid = int(item[2])

        if isinstance(svg_doc, bytes):
            svg_text = svg_doc.decode("utf-8")
        else:
            svg_text = str(svg_doc)

        svg_index = len(svg_docs)
        svg_docs.append(compact_svg(svg_text))

        for gid in range(start_gid, end_gid + 1):
            if gid < 0 or gid >= len(glyph_order):
                continue

            glyph_name = glyph_order[gid]

            for codepoint in glyph_name_to_codepoints.get(glyph_name, []):
                codepoint_to_svg_index[codepoint] = svg_index

    # fallback لأي كود موجود في cmap لكن مش مربوط بـ SVG
    for codepoint, glyph_name in cmap.items():
        if codepoint in codepoint_to_svg_index:
            continue

        fallback_svg = build_compact_svg_from_glyf(font, glyph_name)

        if fallback_svg is None:
            continue

        fallback_index = len(svg_docs)
        svg_docs.append(fallback_svg)
        codepoint_to_svg_index[codepoint] = fallback_index
        glyf_fallback_codepoints[codepoint] = fallback_index

    return {
        "svgDocs": svg_docs,
        "codepointToSvgIndex": codepoint_to_svg_index,
        "glyfFallbackCodepoints": glyf_fallback_codepoints,
    }


def build_page_pack(
    *,
    page_number: int,
    font_path: Path,
    layout_lines: List[LayoutLine],
    words_by_id: Dict[int, QuranWord],
    include_text: bool,
    include_location: bool,
) -> Dict[str, Any]:
    font = TTFont(str(font_path))

    if "SVG " not in font:
        raise RuntimeError(f"Font page {page_number} does not contain SVG table.")

    units_per_em = int(font["head"].unitsPerEm)
    svg_maps = build_svg_doc_maps(font)

    used_svg_indices: Dict[int, int] = {}
    compact_svg_docs: List[Dict[str, Optional[str]]] = []

    def get_compact_svg_index(original_index: int) -> int:
        if original_index in used_svg_indices:
            return used_svg_indices[original_index]

        new_index = len(compact_svg_docs)
        used_svg_indices[original_index] = new_index
        compact_svg_docs.append(svg_maps["svgDocs"][original_index])
        return new_index

    output_lines: List[Dict[str, Any]] = []

    missing_words = 0
    missing_glyphs = 0
    total_words = 0
    total_chars = 0
    glyf_fallbacks_used = 0

    for line in layout_lines:
        output_words: List[Dict[str, Any]] = []

        if line.first_word_id is not None and line.last_word_id is not None:
            for word_id in range(line.first_word_id, line.last_word_id + 1):
                word = words_by_id.get(word_id)

                if word is None:
                    missing_words += 1
                    output_words.append({"id": word_id, "m": 1})
                    continue

                total_words += 1
                glyph_refs: List[int] = []

                for char in word.text:
                    total_chars += 1
                    codepoint = ord(char)
                    svg_index = svg_maps["codepointToSvgIndex"].get(codepoint)

                    if svg_index is None:
                        missing_glyphs += 1
                        continue

                    if codepoint in svg_maps["glyfFallbackCodepoints"]:
                        glyf_fallbacks_used += 1

                    glyph_refs.append(get_compact_svg_index(svg_index))

                word_payload: Dict[str, Any] = {
                    "id": word.id,
                    "s": word.surah,
                    "a": word.ayah,
                    "w": word.word,
                    "g": glyph_refs,
                }

                if include_text:
                    word_payload["t"] = word.text

                if include_location:
                    word_payload["loc"] = word.location

                output_words.append(word_payload)

        output_lines.append(
            {
                "n": line.line_number,
                "type": line.line_type,
                "center": 1 if line.is_centered else 0,
                "surah": line.surah_number,
                "first": line.first_word_id,
                "last": line.last_word_id,
                "words": output_words,
            }
        )

    return {
        "v": 3,
        "kind": "qpc_svg_page_pack",
        "page": page_number,
        "u": units_per_em,
        "tw": total_words,
        "tc": total_chars,
        "mw": missing_words,
        "mg": missing_glyphs,
        "gf": glyf_fallbacks_used,
        "svgs": compact_svg_docs,
        "lines": output_lines,
    }


def write_gzip_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    with gzip.open(path, "wb", compresslevel=9) as file:
        file.write(raw)


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def build_pages(args: argparse.Namespace) -> None:
    pages = parse_pages(args.pages)

    layout_db = Path(args.layout)
    words_json = Path(args.words)
    woff2_dir = Path(args.woff2_dir)
    out_dir = Path(args.out_dir)

    words_by_id = load_words_by_id(words_json)
    lines_by_page = load_all_layout_lines(layout_db)

    total_gzip_size = 0
    total_words = 0
    total_missing_words = 0
    total_missing_glyphs = 0
    total_glyf_fallbacks = 0

    largest_page = None
    largest_size = 0

    report_pages: List[Dict[str, Any]] = []

    out_dir.mkdir(parents=True, exist_ok=True)

    for index, page in enumerate(pages, start=1):
        font_path = download_woff2_if_needed(
            page=page,
            theme=args.theme,
            woff2_dir=woff2_dir,
        )

        layout_lines = lines_by_page.get(page, [])

        if not layout_lines:
            raise RuntimeError(f"No layout lines for page {page}")

        pack = build_page_pack(
            page_number=page,
            font_path=font_path,
            layout_lines=layout_lines,
            words_by_id=words_by_id,
            include_text=args.include_text,
            include_location=args.include_location,
        )

        page_file = out_dir / f"page_{page:03}.json.gz"
        write_gzip_json(page_file, pack)

        page_size = page_file.stat().st_size

        total_gzip_size += page_size
        total_words += int(pack["tw"])
        total_missing_words += int(pack["mw"])
        total_missing_glyphs += int(pack["mg"])
        total_glyf_fallbacks += int(pack["gf"])

        if page_size > largest_size:
            largest_size = page_size
            largest_page = page

        report_pages.append(
            {
                "page": page,
                "words": pack["tw"],
                "chars": pack["tc"],
                "svgDocs": len(pack["svgs"]),
                "missingWords": pack["mw"],
                "missingGlyphs": pack["mg"],
                "glyfFallbacks": pack["gf"],
                "gzipBytes": page_size,
            }
        )

        print(
            f"[{index}/{len(pages)}] page {page:03} | "
            f"words={pack['tw']} | "
            f"svg={len(pack['svgs'])} | "
            f"missingGlyphs={pack['mg']} | "
            f"glyfFallbacks={pack['gf']} | "
            f"size={format_kb(page_size)}"
        )

    manifest = {
        "version": 2,
        "kind": "qpc_svg_pages_manifest",
        "theme": args.theme,
        "pagesCount": len(pages),
        "includeText": args.include_text,
        "includeLocation": args.include_location,
        "totalWords": total_words,
        "missingWords": total_missing_words,
        "missingGlyphs": total_missing_glyphs,
        "glyfFallbacks": total_glyf_fallbacks,
        "totalGzipBytes": total_gzip_size,
        "totalGzipMB": total_gzip_size / (1024 * 1024),
        "largestPage": largest_page,
        "largestPageBytes": largest_size,
        "pages": report_pages,
    }

    write_json(out_dir / "manifest.json", manifest)

    print("")
    print("Done ✅")
    print(f"Pages: {len(pages)}")
    print(f"Total words: {total_words}")
    print(f"Missing words: {total_missing_words}")
    print(f"Missing glyphs: {total_missing_glyphs}")
    print(f"Glyf fallbacks used: {total_glyf_fallbacks}")
    print(f"Total gzip size: {format_mb(total_gzip_size)}")
    print(f"Largest page: {largest_page} | {format_kb(largest_size)}")
    print(f"Manifest: {out_dir / 'manifest.json'}")


def inspect_page(args: argparse.Namespace) -> None:
    page_file = Path(args.page_file)

    if not page_file.exists():
        raise FileNotFoundError(page_file)

    with gzip.open(page_file, "rb") as file:
        data = json.loads(file.read().decode("utf-8"))

    print("Done ✅")
    print(f"Page file: {page_file}")
    print(f"Page: {data.get('page')}")
    print(f"Units per em: {data.get('u')}")
    print(f"Total words: {data.get('tw')}")
    print(f"Total chars: {data.get('tc')}")
    print(f"Missing words: {data.get('mw')}")
    print(f"Missing glyphs: {data.get('mg')}")
    print(f"Glyf fallbacks used: {data.get('gf')}")
    print(f"SVG docs: {len(data.get('svgs', []))}")
    print(f"Lines: {len(data.get('lines', []))}")
    print(f"File size: {format_kb(page_file.stat().st_size)}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="QPC SVG Engine Builder - organized pipeline"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    build_parser = subparsers.add_parser("build-pages")
    build_parser.add_argument("--pages", default="all")
    build_parser.add_argument("--theme", default="light", choices=["light", "dark", "sepia"])
    build_parser.add_argument("--layout", required=True)
    build_parser.add_argument("--words", required=True)
    build_parser.add_argument("--woff2-dir", required=True)
    build_parser.add_argument("--out-dir", required=True)
    build_parser.add_argument("--include-text", action="store_true")
    build_parser.add_argument("--include-location", action="store_true")
    build_parser.set_defaults(func=build_pages)

    inspect_parser = subparsers.add_parser("inspect-page")
    inspect_parser.add_argument("--page-file", required=True)
    inspect_parser.set_defaults(func=inspect_page)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()