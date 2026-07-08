import argparse
import gzip
import hashlib
import json
import os
import sqlite3
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

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


def make_json_safe_point(value: Any) -> Any:
    if isinstance(value, tuple):
        return [make_json_safe_point(item) for item in value]

    if isinstance(value, list):
        return [make_json_safe_point(item) for item in value]

    if isinstance(value, float):
        if value.is_integer():
            return int(value)

    return value


def parse_pages_argument(value: str) -> List[int]:
    text = value.strip()

    if text.lower() == "all":
        return list(range(1, 605))

    pages: List[int] = []

    for part in text.split(","):
        section = part.strip()

        if not section:
            continue

        if "-" in section:
            start_text, end_text = section.split("-", 1)
            start = int(start_text.strip())
            end = int(end_text.strip())

            if start > end:
                start, end = end, start

            pages.extend(range(start, end + 1))
        else:
            pages.append(int(section))

    cleaned = sorted(set(page for page in pages if 1 <= page <= 604))

    if not cleaned:
        raise ValueError("No valid pages selected. Use e.g. --pages 1,2,100 or --pages 1-604 or --pages all")

    return cleaned


def load_layout_lines_for_pages(
    layout_db_path: str,
    pages: List[int],
) -> Dict[int, List[LayoutLine]]:
    if not os.path.exists(layout_db_path):
        raise FileNotFoundError(f"Layout database not found: {layout_db_path}")

    connection = sqlite3.connect(layout_db_path)
    connection.row_factory = sqlite3.Row

    lines_by_page: Dict[int, List[LayoutLine]] = {page: [] for page in pages}

    try:
        for page_number in pages:
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

            for row in rows:
                lines_by_page[page_number].append(
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
    finally:
        connection.close()

    return lines_by_page


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


def extract_font_from_pack(
    font_pack_path: str,
    page_number: int,
    temp_dir: Path,
) -> Path:
    if not os.path.exists(font_pack_path):
        raise FileNotFoundError(f"Font pack not found: {font_pack_path}")

    if not zipfile.is_zipfile(font_pack_path):
        raise ValueError(
            "Font pack is not a ZIP file. "
            "Even if the extension is .bz2, it must contain p1.ttf ... p604.ttf as ZIP entries."
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
                f"Example entries: {list(sorted(names))[:10]}"
            )

        with archive.open(font_name) as source:
            target_path.write_bytes(source.read())

    return target_path


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


def get_glyph_advance(glyph_set: Any, glyph_name: str) -> float:
    glyph = glyph_set[glyph_name]
    width = getattr(glyph, "width", 0)

    try:
        return float(width)
    except Exception:
        return 0.0


def canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )


def glyph_hash_payload(
    *,
    advance: float,
    bounds: Optional[List[float]],
    commands: List[Dict[str, Any]],
) -> Dict[str, Any]:
    return {
        "advance": advance,
        "bounds": bounds,
        "commands": commands,
    }


class GlyphStore:
    def __init__(self) -> None:
        self._hash_to_id: Dict[str, str] = {}
        self.glyphs: Dict[str, Dict[str, Any]] = {}
        self.count = 0

    def add_glyph(
        self,
        *,
        glyph_name: str,
        codepoint: int,
        advance: float,
        bounds: Optional[List[float]],
        commands: List[Dict[str, Any]],
    ) -> str:
        payload = glyph_hash_payload(
            advance=advance,
            bounds=bounds,
            commands=commands,
        )

        digest = hashlib.sha1(canonical_json(payload).encode("utf-8")).hexdigest()

        existing_id = self._hash_to_id.get(digest)

        if existing_id is not None:
            return existing_id

        self.count += 1
        glyph_id = f"g{self.count}"

        self._hash_to_id[digest] = glyph_id

        self.glyphs[glyph_id] = {
            "glyphName": glyph_name,
            "codepoint": codepoint,
            "advance": advance,
            "bounds": bounds,
            "commands": commands,
        }

        return glyph_id


def extract_word_glyph_refs(
    *,
    font: TTFont,
    text: str,
    glyph_store: GlyphStore,
) -> Dict[str, Any]:
    cmap = font.getBestCmap()
    glyph_set = font.getGlyphSet()

    glyph_refs: List[Dict[str, Any]] = []
    total_advance = 0.0
    missing_glyphs = 0

    for character in text:
        codepoint = ord(character)
        glyph_name = cmap.get(codepoint)

        if glyph_name is None:
            glyph_refs.append(
                {
                    "glyphId": None,
                    "codepoint": codepoint,
                    "advance": 0.0,
                    "missing": True,
                }
            )
            missing_glyphs += 1
            continue

        advance = get_glyph_advance(glyph_set, glyph_name)
        bounds = get_glyph_bounds(glyph_set, glyph_name)
        commands = get_glyph_commands(glyph_set, glyph_name)

        glyph_id = glyph_store.add_glyph(
            glyph_name=glyph_name,
            codepoint=codepoint,
            advance=advance,
            bounds=bounds,
            commands=commands,
        )

        glyph_refs.append(
            {
                "glyphId": glyph_id,
                "codepoint": codepoint,
                "advance": advance,
                "missing": False,
            }
        )

        total_advance += advance

    return {
        "text": text,
        "glyphRefs": glyph_refs,
        "advance": total_advance,
        "missingGlyphs": missing_glyphs,
    }


def build_page_data(
    *,
    page_number: int,
    layout_lines: List[LayoutLine],
    words_by_id: Dict[int, QuranWord],
    font: TTFont,
    glyph_store: GlyphStore,
) -> Dict[str, Any]:
    page_lines: List[Dict[str, Any]] = []

    for line in layout_lines:
        words: List[Dict[str, Any]] = []
        line_advance = 0.0
        missing_words = 0
        missing_glyphs = 0

        if line.first_word_id is not None and line.last_word_id is not None:
            for word_id in range(line.first_word_id, line.last_word_id + 1):
                quran_word = words_by_id.get(word_id)

                if quran_word is None:
                    missing_words += 1
                    words.append(
                        {
                            "id": word_id,
                            "missing": True,
                        }
                    )
                    continue

                glyph_ref_record = extract_word_glyph_refs(
                    font=font,
                    text=quran_word.text,
                    glyph_store=glyph_store,
                )

                line_advance += float(glyph_ref_record["advance"])
                missing_glyphs += int(glyph_ref_record["missingGlyphs"])

                words.append(
                    {
                        "id": quran_word.id,
                        "surah": quran_word.surah,
                        "ayah": quran_word.ayah,
                        "word": quran_word.word,
                        "location": quran_word.location,
                        "text": quran_word.text,
                        "advance": glyph_ref_record["advance"],
                        "glyphRefs": glyph_ref_record["glyphRefs"],
                        "missing": False,
                    }
                )

        page_lines.append(
            {
                "lineNumber": line.line_number,
                "lineType": line.line_type,
                "isCentered": line.is_centered,
                "surahNumber": line.surah_number,
                "firstWordId": line.first_word_id,
                "lastWordId": line.last_word_id,
                "advance": line_advance,
                "missingWords": missing_words,
                "missingGlyphs": missing_glyphs,
                "words": words,
            }
        )

    return {
        "pageNumber": page_number,
        "lines": page_lines,
    }


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w", encoding="utf-8") as file:
        json.dump(value, file, ensure_ascii=False, separators=(",", ":"))


def write_gzip_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    with gzip.open(path, "wb", compresslevel=9) as file:
        file.write(raw)


def export_optimized_pack(
    *,
    font_pack_path: str,
    layout_db_path: str,
    qpc_json_path: str,
    pages_arg: str,
    output_dir: str,
) -> None:
    pages = parse_pages_argument(pages_arg)

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    temp_dir = output_path / "_tmp_fonts"
    temp_dir.mkdir(parents=True, exist_ok=True)

    words_by_id = load_words_by_id(qpc_json_path)
    lines_by_page = load_layout_lines_for_pages(layout_db_path, pages)

    glyph_store = GlyphStore()
    pages_output: Dict[str, Any] = {}

    total_missing_words = 0
    total_missing_glyphs = 0
    total_words = 0

    units_per_em: Optional[int] = None

    for index, page_number in enumerate(pages, start=1):
        layout_lines = lines_by_page.get(page_number, [])

        if not layout_lines:
            print(f"Warning: no layout lines found for page {page_number}")
            continue

        font_path = extract_font_from_pack(
            font_pack_path=font_pack_path,
            page_number=page_number,
            temp_dir=temp_dir,
        )

        font = TTFont(str(font_path))

        if units_per_em is None:
            units_per_em = int(font["head"].unitsPerEm)

        page_data = build_page_data(
            page_number=page_number,
            layout_lines=layout_lines,
            words_by_id=words_by_id,
            font=font,
            glyph_store=glyph_store,
        )

        for line in page_data["lines"]:
            total_missing_words += int(line.get("missingWords", 0))
            total_missing_glyphs += int(line.get("missingGlyphs", 0))
            total_words += len(line.get("words", []))

        pages_output[str(page_number)] = page_data

        print(
            f"[{index}/{len(pages)}] page {page_number} done | "
            f"glyphs dict: {len(glyph_store.glyphs)}"
        )

    pack = {
        "version": 2,
        "source": "QPC V2 optimized glyph-reference pack",
        "unitsPerEm": units_per_em,
        "pagesCount": len(pages_output),
        "glyphsCount": len(glyph_store.glyphs),
        "wordsCount": total_words,
        "missingWords": total_missing_words,
        "missingGlyphs": total_missing_glyphs,
        "glyphs": glyph_store.glyphs,
        "pages": pages_output,
    }

    json_file = output_path / "qpc_optimized_pack.json"
    gzip_file = output_path / "qpc_optimized_pack.json.gz"

    write_json(json_file, pack)
    write_gzip_json(gzip_file, pack)

    raw_size_kb = json_file.stat().st_size / 1024
    gzip_size_kb = gzip_file.stat().st_size / 1024

    print("")
    print("Done ✅")
    print(f"Pages exported: {len(pages_output)}")
    print(f"Units per em: {units_per_em}")
    print(f"Total words: {total_words}")
    print(f"Unique glyph outlines: {len(glyph_store.glyphs)}")
    print(f"Missing words: {total_missing_words}")
    print(f"Missing glyphs: {total_missing_glyphs}")
    print(f"JSON size: {raw_size_kb:.2f} KB")
    print(f"GZIP size: {gzip_size_kb:.2f} KB")
    print(f"Output JSON: {json_file}")
    print(f"Output GZIP: {gzip_file}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export optimized QPC V2 pages using a shared glyph dictionary."
    )

    parser.add_argument(
        "--fonts",
        required=True,
        help="Path to qpc-fonts.zip containing p1.ttf ... p604.ttf.",
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
        "--pages",
        required=True,
        help="Pages to export. Examples: 1,2,100 or 1-10 or all.",
    )

    parser.add_argument(
        "--out-dir",
        required=True,
        help="Output directory.",
    )

    args = parser.parse_args()

    export_optimized_pack(
        font_pack_path=args.fonts,
        layout_db_path=args.layout,
        qpc_json_path=args.words,
        pages_arg=args.pages,
        output_dir=args.out_dir,
    )


if __name__ == "__main__":
    main()