import argparse
import gzip
import json
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from fontTools.ttLib import TTFont


def format_kb(size: int) -> str:
    return f"{size / 1024:.2f} KB"


def get_svg_table_docs(font: TTFont) -> List[Any]:
    svg_table = font["SVG "]

    docs = getattr(svg_table, "docList", None)

    if docs is None:
        docs = getattr(svg_table, "svgDocList", None)

    if docs is None:
        raise RuntimeError("Could not find SVG doc list in fontTools SVG table.")

    return docs


def normalize_svg(svg_text: str) -> str:
    text = svg_text.strip()

    text = re.sub(r">\s+<", "><", text)
    text = re.sub(r"\s+", " ", text)

    return text.strip()


def extract_svg_docs(font: TTFont) -> Dict[str, Any]:
    docs = get_svg_table_docs(font)
    glyph_order = font.getGlyphOrder()
    cmap = font.getBestCmap()

    glyph_name_to_codepoints: Dict[str, List[int]] = {}

    for codepoint, glyph_name in cmap.items():
        glyph_name_to_codepoints.setdefault(glyph_name, []).append(codepoint)

    result_docs: List[Dict[str, Any]] = []

    glyph_to_svg_doc_index: Dict[str, int] = {}
    codepoint_to_svg_doc_index: Dict[str, int] = {}

    for index, item in enumerate(docs):
        # fontTools غالبًا بيخزنها كـ:
        # (svgDoc, startGlyphID, endGlyphID)
        if len(item) < 3:
            continue

        svg_doc = item[0]
        start_gid = int(item[1])
        end_gid = int(item[2])

        if isinstance(svg_doc, bytes):
            svg_text = svg_doc.decode("utf-8")
        else:
            svg_text = str(svg_doc)

        normalized_svg = normalize_svg(svg_text)

        result_docs.append(
            {
                "index": index,
                "startGlyphId": start_gid,
                "endGlyphId": end_gid,
                "svg": normalized_svg,
            }
        )

        for gid in range(start_gid, end_gid + 1):
            if gid < 0 or gid >= len(glyph_order):
                continue

            glyph_name = glyph_order[gid]
            glyph_to_svg_doc_index[glyph_name] = index

            for codepoint in glyph_name_to_codepoints.get(glyph_name, []):
                codepoint_to_svg_doc_index[str(codepoint)] = index

    return {
        "docs": result_docs,
        "glyphToSvgDocIndex": glyph_to_svg_doc_index,
        "codepointToSvgDocIndex": codepoint_to_svg_doc_index,
    }


def extract_font_svg_pack(font_path: str) -> Dict[str, Any]:
    if not os.path.exists(font_path):
        raise FileNotFoundError(font_path)

    font = TTFont(font_path)

    cmap = font.getBestCmap()

    svg_data = extract_svg_docs(font)

    return {
        "version": 1,
        "source": "WOFF2 SVG glyph extraction",
        "font": str(font_path),
        "unitsPerEm": int(font["head"].unitsPerEm),
        "glyphsCount": len(font.getGlyphOrder()),
        "cmapCount": len(cmap),
        "svgDocsCount": len(svg_data["docs"]),
        "svg": svg_data,
    }


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":"))

    path.write_text(raw, encoding="utf-8")


def write_gzip_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    with gzip.open(path, "wb", compresslevel=9) as file:
        file.write(raw)


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument("--font", required=True)
    parser.add_argument("--out", required=True)

    args = parser.parse_args()

    pack = extract_font_svg_pack(args.font)

    out_path = Path(args.out)
    gzip_path = Path(str(out_path) + ".gz")

    write_json(out_path, pack)
    write_gzip_json(gzip_path, pack)

    print("Done ✅")
    print(f"Font: {args.font}")
    print(f"Units per em: {pack['unitsPerEm']}")
    print(f"Glyphs count: {pack['glyphsCount']}")
    print(f"CMAP count: {pack['cmapCount']}")
    print(f"SVG docs count: {pack['svgDocsCount']}")
    print(f"JSON: {out_path} | {format_kb(out_path.stat().st_size)}")
    print(f"GZIP: {gzip_path} | {format_kb(gzip_path.stat().st_size)}")


if __name__ == "__main__":
    main()