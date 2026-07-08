import argparse
import json
import os
import sqlite3
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.recordingPen import RecordingPen
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


def load_layout_lines(layout_db_path: str, page_number: int) -> List[LayoutLine]:
    if not os.path.exists(layout_db_path):
        raise FileNotFoundError(f"Layout database not found: {layout_db_path}")

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

    lines: List[LayoutLine] = []

    for row in rows:
        lines.append(
            LayoutLine(
                page_number=int(row["page_number"]),
                line_number=int(row["line_number"]),
                line_type=str(row["line_type"]),
                is_centered=as_optional_int(row["is_centered"]) == 1,
                first_word_id=as_optional_int(row["first_word_id"]),
                last_word_id=as_optional_int(row["last_word_id"]),
                surah_number=as_optional_int(row["surah_number"]),
            )
        )

    return lines


def load_words_by_id(qpc_json_path: str) -> Dict[int, QuranWord]:
    if not os.path.exists(qpc_json_path):
        raise FileNotFoundError(f"QPC JSON not found: {qpc_json_path}")

    with open(qpc_json_path, "r", encoding="utf-8") as file:
        raw_data = json.load(file)

    words_by_id: Dict[int, QuranWord] = {}

    for _, value in raw_data.items():
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


def extract_font_from_pack(font_pack_path: str, page_number: int, temp_dir: Path) -> Path:
    if not os.path.exists(font_pack_path):
        raise FileNotFoundError(f"Font pack not found: {font_pack_path}")

    if not zipfile.is_zipfile(font_pack_path):
        raise ValueError(
            "Font pack is not a ZIP file. "
            "Even if the file extension is .bz2, it must contain p1.ttf ... p604.ttf as ZIP entries."
        )

    font_name = f"p{page_number}.ttf"
    target_path = temp_dir / font_name

    if target_path.exists():
        return target_path

    with zipfile.ZipFile(font_pack_path, "r") as archive:
        names = set(archive.namelist())

        if font_name not in names:
            raise FileNotFoundError(
                f"{font_name} not found inside font pack. "
                f"Example available entries: {list(sorted(names))[:10]}"
            )

        with archive.open(font_name) as source:
            target_path.write_bytes(source.read())

    return target_path


def make_json_safe_point(value: Any) -> Any:
    if isinstance(value, tuple):
        return [make_json_safe_point(item) for item in value]

    if isinstance(value, list):
        return [make_json_safe_point(item) for item in value]

    return value


def get_glyph_bounds(glyph_set: Any, glyph_name: str) -> Optional[List[float]]:
    glyph = glyph_set[glyph_name]

    bounds_pen = BoundsPen(glyph_set)

    try:
        glyph.draw(bounds_pen)
    except Exception:
        return None

    if bounds_pen.bounds is None:
        return None

    x_min, y_min, x_max, y_max = bounds_pen.bounds

    return [
        float(x_min),
        float(y_min),
        float(x_max),
        float(y_max),
    ]


def get_glyph_commands(glyph_set: Any, glyph_name: str) -> List[Dict[str, Any]]:
    glyph = glyph_set[glyph_name]

    pen = RecordingPen()

    try:
        glyph.draw(pen)
    except Exception:
        return []

    commands: List[Dict[str, Any]] = []

    for operation, arguments in pen.value:
        commands.append(
            {
                "op": operation,
                "args": make_json_safe_point(arguments),
            }
        )

    return commands


def get_glyph_advance(glyph_set: Any, glyph_name: str) -> float:
    glyph = glyph_set[glyph_name]

    width = getattr(glyph, "width", 0)

    try:
        return float(width)
    except Exception:
        return 0.0


def extract_glyph_record(font: TTFont, text: str) -> Dict[str, Any]:
    cmap = font.getBestCmap()
    glyph_set = font.getGlyphSet()

    glyph_records: List[Dict[str, Any]] = []
    total_advance = 0.0

    for character in text:
        codepoint = ord(character)
        glyph_name = cmap.get(codepoint)

        if glyph_name is None:
            glyph_records.append(
                {
                    "char": character,
                    "codepoint": codepoint,
                    "glyphName": None,
                    "advance": 0.0,
                    "bounds": None,
                    "commands": [],
                    "missing": True,
                }
            )
            continue

        advance = get_glyph_advance(glyph_set, glyph_name)
        bounds = get_glyph_bounds(glyph_set, glyph_name)
        commands = get_glyph_commands(glyph_set, glyph_name)

        glyph_records.append(
            {
                "char": character,
                "codepoint": codepoint,
                "glyphName": glyph_name,
                "advance": advance,
                "bounds": bounds,
                "commands": commands,
                "missing": False,
            }
        )

        total_advance += advance

    return {
        "text": text,
        "glyphs": glyph_records,
        "advance": total_advance,
    }


def build_page_render_data(
    *,
    page_number: int,
    layout_lines: List[LayoutLine],
    words_by_id: Dict[int, QuranWord],
    font: TTFont,
) -> Dict[str, Any]:
    units_per_em = int(font["head"].unitsPerEm)

    result_lines: List[Dict[str, Any]] = []

    for line in layout_lines:
        line_words: List[Dict[str, Any]] = []

        if line.first_word_id is not None and line.last_word_id is not None:
            for word_id in range(line.first_word_id, line.last_word_id + 1):
                quran_word = words_by_id.get(word_id)

                if quran_word is None:
                    line_words.append(
                        {
                            "id": word_id,
                            "missing": True,
                            "error": "Word id not found in qpc-v2.json",
                        }
                    )
                    continue

                glyph_record = extract_glyph_record(font, quran_word.text)

                line_words.append(
                    {
                        "id": quran_word.id,
                        "surah": quran_word.surah,
                        "ayah": quran_word.ayah,
                        "word": quran_word.word,
                        "location": quran_word.location,
                        "text": quran_word.text,
                        "glyphRecord": glyph_record,
                        "missing": False,
                    }
                )

        line_advance = sum(
            float(item.get("glyphRecord", {}).get("advance", 0.0))
            for item in line_words
            if not item.get("missing", False)
        )

        result_lines.append(
            {
                "pageNumber": line.page_number,
                "lineNumber": line.line_number,
                "lineType": line.line_type,
                "isCentered": line.is_centered,
                "surahNumber": line.surah_number,
                "firstWordId": line.first_word_id,
                "lastWordId": line.last_word_id,
                "advance": line_advance,
                "words": line_words,
            }
        )

    return {
        "version": 1,
        "source": "QPC V2 glyph extraction experiment",
        "pageNumber": page_number,
        "unitsPerEm": units_per_em,
        "linesCount": len(result_lines),
        "lines": result_lines,
    }


def export_page(
    *,
    font_pack_path: str,
    layout_db_path: str,
    qpc_json_path: str,
    page_number: int,
    output_path: str,
) -> None:
    if page_number < 1 or page_number > 604:
        raise ValueError("page_number must be between 1 and 604")

    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)

    temp_dir = output_file.parent / "_tmp_fonts"
    temp_dir.mkdir(parents=True, exist_ok=True)

    font_path = extract_font_from_pack(
        font_pack_path=font_pack_path,
        page_number=page_number,
        temp_dir=temp_dir,
    )

    layout_lines = load_layout_lines(
        layout_db_path=layout_db_path,
        page_number=page_number,
    )

    if not layout_lines:
        raise ValueError(f"No layout lines found for page {page_number}")

    words_by_id = load_words_by_id(qpc_json_path)

    font = TTFont(str(font_path))

    page_data = build_page_render_data(
        page_number=page_number,
        layout_lines=layout_lines,
        words_by_id=words_by_id,
        font=font,
    )

    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(page_data, file, ensure_ascii=False, separators=(",", ":"))

    missing_words = 0
    missing_glyphs = 0
    commands_count = 0

    for line in page_data["lines"]:
        for word in line["words"]:
            if word.get("missing", False):
                missing_words += 1
                continue

            glyph_record = word.get("glyphRecord", {})
            for glyph in glyph_record.get("glyphs", []):
                if glyph.get("missing", False):
                    missing_glyphs += 1

                commands_count += len(glyph.get("commands", []))

    print("Done ✅")
    print(f"Page: {page_number}")
    print(f"Output: {output_file}")
    print(f"Lines: {page_data['linesCount']}")
    print(f"Units per em: {page_data['unitsPerEm']}")
    print(f"Missing words: {missing_words}")
    print(f"Missing glyphs: {missing_glyphs}")
    print(f"Total draw commands: {commands_count}")
    print(f"Output size: {output_file.stat().st_size / 1024:.2f} KB")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export QPC V2 page glyph outlines into JSON render data."
    )

    parser.add_argument(
        "--fonts",
        required=True,
        help="Path to QPC font pack ZIP file. It can have a .bz2 extension if it is actually a ZIP.",
    )

    parser.add_argument(
        "--layout",
        required=True,
        help="Path to qpc-v2-15-lines.db.",
    )

    parser.add_argument(
        "--words",
        required=True,
        help="Path to qpc-v2.json.",
    )

    parser.add_argument(
        "--page",
        required=True,
        type=int,
        help="Page number from 1 to 604.",
    )

    parser.add_argument(
        "--out",
        required=True,
        help="Output JSON path.",
    )

    args = parser.parse_args()

    export_page(
        font_pack_path=args.fonts,
        layout_db_path=args.layout,
        qpc_json_path=args.words,
        page_number=args.page,
        output_path=args.out,
    )


if __name__ == "__main__":
    main()