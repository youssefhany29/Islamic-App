import argparse
import json
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

from fontTools.ttLib import TTFont


@dataclass(frozen=True)
class LayoutLine:
    line_number: int
    line_type: str
    first_word_id: Optional[int]
    last_word_id: Optional[int]


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


def load_layout_lines(layout_db_path: Path, page_number: int) -> List[LayoutLine]:
    connection = sqlite3.connect(str(layout_db_path))
    connection.row_factory = sqlite3.Row

    try:
        rows = connection.execute(
            """
            SELECT line_number, line_type, first_word_id, last_word_id
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
            line_number=int(row["line_number"]),
            line_type=str(row["line_type"]),
            first_word_id=as_optional_int(row["first_word_id"]),
            last_word_id=as_optional_int(row["last_word_id"]),
        )
        for row in rows
    ]


def load_words_by_id(words_json_path: Path) -> Dict[int, QuranWord]:
    with words_json_path.open("r", encoding="utf-8") as file:
        raw_data = json.load(file)

    result: Dict[int, QuranWord] = {}

    for value in raw_data.values():
        word_id = int(value["id"])
        result[word_id] = QuranWord(
            id=word_id,
            surah=int(value["surah"]),
            ayah=int(value["ayah"]),
            word=int(value["word"]),
            location=str(value["location"]),
            text=str(value["text"]),
        )

    return result


def get_svg_docs(font: TTFont) -> List[Any]:
    svg_table = font["SVG "]

    docs = getattr(svg_table, "docList", None)

    if docs is None:
        docs = getattr(svg_table, "svgDocList", None)

    if docs is None:
        raise RuntimeError("SVG docs not found in font.")

    return docs


def build_codepoint_to_svg_index(font: TTFont) -> Dict[int, int]:
    docs = get_svg_docs(font)
    glyph_order = font.getGlyphOrder()
    cmap = font.getBestCmap()

    glyph_name_to_codepoints: Dict[str, List[int]] = {}

    for codepoint, glyph_name in cmap.items():
        glyph_name_to_codepoints.setdefault(glyph_name, []).append(codepoint)

    codepoint_to_svg_index: Dict[int, int] = {}

    for svg_index, item in enumerate(docs):
        if len(item) < 3:
            continue

        start_gid = int(item[1])
        end_gid = int(item[2])

        for gid in range(start_gid, end_gid + 1):
            if gid < 0 or gid >= len(glyph_order):
                continue

            glyph_name = glyph_order[gid]

            for codepoint in glyph_name_to_codepoints.get(glyph_name, []):
                codepoint_to_svg_index[codepoint] = svg_index

    return codepoint_to_svg_index


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--page", required=True, type=int)
    parser.add_argument("--font", required=True)
    parser.add_argument("--layout", required=True)
    parser.add_argument("--words", required=True)
    args = parser.parse_args()

    page_number = args.page
    font_path = Path(args.font)
    layout_path = Path(args.layout)
    words_path = Path(args.words)

    font = TTFont(str(font_path))
    cmap = font.getBestCmap()
    glyph_order = font.getGlyphOrder()
    codepoint_to_svg_index = build_codepoint_to_svg_index(font)

    lines = load_layout_lines(layout_path, page_number)
    words_by_id = load_words_by_id(words_path)

    print("Debug missing SVG glyph mappings")
    print(f"Page: {page_number}")
    print(f"Font: {font_path}")
    print(f"CMAP chars: {len(cmap)}")
    print(f"SVG mapped chars: {len(codepoint_to_svg_index)}")
    print("")

    found_missing = False

    for line in lines:
        if line.first_word_id is None or line.last_word_id is None:
            continue

        for word_id in range(line.first_word_id, line.last_word_id + 1):
            word = words_by_id.get(word_id)

            if word is None:
                print(f"Missing word id in JSON: {word_id}")
                continue

            for char_index, char in enumerate(word.text):
                codepoint = ord(char)
                glyph_name = cmap.get(codepoint)

                has_cmap = codepoint in cmap
                has_svg = codepoint in codepoint_to_svg_index

                if not has_svg:
                    found_missing = True

                    gid = None
                    if glyph_name in glyph_order:
                        gid = glyph_order.index(glyph_name)

                    print("Missing SVG mapping found ❌")
                    print(f"Line number: {line.line_number}")
                    print(f"Word id: {word.id}")
                    print(f"Location: {word.location}")
                    print(f"Surah: {word.surah}")
                    print(f"Ayah: {word.ayah}")
                    print(f"Word: {word.word}")
                    print(f"Text: {word.text}")
                    print(f"Char index: {char_index}")
                    print(f"Char: {char}")
                    print(f"Codepoint decimal: {codepoint}")
                    print(f"Codepoint hex: U+{codepoint:04X}")
                    print(f"Glyph name: {glyph_name}")
                    print(f"Glyph id: {gid}")
                    print(f"Exists in cmap: {has_cmap}")
                    print(f"Exists in SVG mapping: {has_svg}")
                    print("")

    if not found_missing:
        print("No missing SVG mappings ✅")


if __name__ == "__main__":
    main()