import argparse
import gzip
import json
import os
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

from fontTools.ttLib import TTFont


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


def normalize_svg(svg_text: str) -> str:
    text = svg_text.strip()
    text = re.sub(r">\s+<", "><", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def load_layout_lines(layout_db_path: str, page_number: int) -> List[LayoutLine]:
    if not os.path.exists(layout_db_path):
        raise FileNotFoundError(layout_db_path)

    connection = sqlite3.connect(layout_db_path)
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
            WHERE page_number = ?
            ORDER BY line_number ASC
            """,
            (page_number,),
        ).fetchall()
    finally:
        connection.close()

    return [
        LayoutLine(
            page_number=int(row["page_number"]),
            line_number=int(row["line_number"]),
            line_type=str(row["line_type"]),
            is_centered=as_optional_int(row["is_centered"]) == 1,
            first_word_id=as_optional_int(row["first_word_id"]),
            last_word_id=as_optional_int(row["last_word_id"]),
            surah_number=as_optional_int(row["surah_number"]),
        )
        for row in rows
    ]


def load_words_by_id(words_json_path: str) -> Dict[int, QuranWord]:
    if not os.path.exists(words_json_path):
        raise FileNotFoundError(words_json_path)

    with open(words_json_path, "r", encoding="utf-8") as file:
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


def get_svg_docs(font: TTFont) -> List[Any]:
    svg_table = font["SVG "]

    docs = getattr(svg_table, "docList", None)
    if docs is None:
        docs = getattr(svg_table, "svgDocList", None)

    if docs is None:
        raise RuntimeError("SVG docs not found in font.")

    return docs


def build_svg_doc_maps(font: TTFont) -> Dict[str, Any]:
    docs = get_svg_docs(font)
    glyph_order = font.getGlyphOrder()
    cmap = font.getBestCmap()

    glyph_name_to_codepoints: Dict[str, List[int]] = {}

    for codepoint, glyph_name in cmap.items():
        glyph_name_to_codepoints.setdefault(glyph_name, []).append(codepoint)

    svg_docs: List[str] = []
    glyph_to_svg_index: Dict[str, int] = {}
    codepoint_to_svg_index: Dict[int, int] = {}

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
        svg_docs.append(normalize_svg(svg_text))

        for gid in range(start_gid, end_gid + 1):
            if gid < 0 or gid >= len(glyph_order):
                continue

            glyph_name = glyph_order[gid]
            glyph_to_svg_index[glyph_name] = svg_index

            for codepoint in glyph_name_to_codepoints.get(glyph_name, []):
                codepoint_to_svg_index[codepoint] = svg_index

    return {
        "svgDocs": svg_docs,
        "glyphToSvgIndex": glyph_to_svg_index,
        "codepointToSvgIndex": codepoint_to_svg_index,
    }


def build_page_pack(
    *,
    page_number: int,
    font_path: str,
    layout_db_path: str,
    words_json_path: str,
) -> Dict[str, Any]:
    font = TTFont(font_path)

    if "SVG " not in font:
        raise RuntimeError("Font does not contain SVG table.")

    units_per_em = int(font["head"].unitsPerEm)
    cmap = font.getBestCmap()
    svg_maps = build_svg_doc_maps(font)

    layout_lines = load_layout_lines(layout_db_path, page_number)
    words_by_id = load_words_by_id(words_json_path)

    used_svg_indices: Dict[int, int] = {}
    compact_svg_docs: List[str] = []

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

    for line in layout_lines:
        output_words: List[Dict[str, Any]] = []

        if line.first_word_id is not None and line.last_word_id is not None:
            for word_id in range(line.first_word_id, line.last_word_id + 1):
                word = words_by_id.get(word_id)

                if word is None:
                    missing_words += 1
                    output_words.append(
                        {
                            "id": word_id,
                            "m": 1,
                        }
                    )
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

                    glyph_refs.append(get_compact_svg_index(svg_index))

                output_words.append(
                    {
                        "id": word.id,
                        "s": word.surah,
                        "a": word.ayah,
                        "w": word.word,
                        "loc": word.location,
                        "t": word.text,
                        "g": glyph_refs,
                    }
                )

        output_lines.append(
            {
                "n": line.line_number,
                "type": line.line_type,
                "center": line.is_centered,
                "surah": line.surah_number,
                "first": line.first_word_id,
                "last": line.last_word_id,
                "words": output_words,
            }
        )

    return {
        "v": 1,
        "kind": "qpc_svg_page_pack",
        "page": page_number,
        "unitsPerEm": units_per_em,
        "totalWords": total_words,
        "totalChars": total_chars,
        "missingWords": missing_words,
        "missingGlyphs": missing_glyphs,
        "svgDocs": compact_svg_docs,
        "lines": output_lines,
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


def format_kb(size: int) -> str:
    return f"{size / 1024:.2f} KB"


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument("--page", required=True, type=int)
    parser.add_argument("--font", required=True)
    parser.add_argument("--layout", required=True)
    parser.add_argument("--words", required=True)
    parser.add_argument("--out", required=True)

    args = parser.parse_args()

    pack = build_page_pack(
        page_number=args.page,
        font_path=args.font,
        layout_db_path=args.layout,
        words_json_path=args.words,
    )

    out_path = Path(args.out)
    gzip_path = Path(str(out_path) + ".gz")

    write_json(out_path, pack)
    write_gzip_json(gzip_path, pack)

    print("Done ✅")
    print(f"Page: {args.page}")
    print(f"Total words: {pack['totalWords']}")
    print(f"Total chars: {pack['totalChars']}")
    print(f"Missing words: {pack['missingWords']}")
    print(f"Missing glyphs: {pack['missingGlyphs']}")
    print(f"Used SVG docs: {len(pack['svgDocs'])}")
    print(f"JSON: {out_path} | {format_kb(out_path.stat().st_size)}")
    print(f"GZIP: {gzip_path} | {format_kb(gzip_path.stat().st_size)}")


if __name__ == "__main__":
    main()
    