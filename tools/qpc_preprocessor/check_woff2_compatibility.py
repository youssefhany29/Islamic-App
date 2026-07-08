import argparse
import json
import os
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
    connection = sqlite3.connect(layout_db_path)
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


def load_words_by_id(qpc_json_path: str) -> Dict[int, QuranWord]:
    with open(qpc_json_path, "r", encoding="utf-8") as file:
        raw_data = json.load(file)

    result: Dict[int, QuranWord] = {}

    for value in raw_data.values():
        word_id = int(value["id"])
        result[word_id] = QuranWord(
            id=word_id,
            location=str(value["location"]),
            text=str(value["text"]),
        )

    return result


def check_page(
    *,
    page_number: int,
    woff2_path: str,
    layout_db_path: str,
    qpc_json_path: str,
) -> None:
    if not os.path.exists(woff2_path):
        raise FileNotFoundError(f"WOFF2 not found: {woff2_path}")

    font = TTFont(woff2_path)
    cmap = font.getBestCmap()

    lines = load_layout_lines(layout_db_path, page_number)
    words_by_id = load_words_by_id(qpc_json_path)

    total_chars = 0
    missing_chars = 0
    total_words = 0
    missing_words = 0

    missing_examples: List[str] = []

    for line in lines:
        if line.first_word_id is None or line.last_word_id is None:
            continue

        for word_id in range(line.first_word_id, line.last_word_id + 1):
            word = words_by_id.get(word_id)

            if word is None:
                continue

            total_words += 1

            word_missing = False

            for char in word.text:
                total_chars += 1
                codepoint = ord(char)

                if codepoint not in cmap:
                    missing_chars += 1
                    word_missing = True

                    if len(missing_examples) < 10:
                        missing_examples.append(
                            f"word_id={word.id}, location={word.location}, char={char}, codepoint={codepoint}"
                        )

            if word_missing:
                missing_words += 1

    print("Done ✅")
    print(f"Page: {page_number}")
    print(f"WOFF2: {woff2_path}")
    print(f"Total words: {total_words}")
    print(f"Missing words: {missing_words}")
    print(f"Total chars: {total_chars}")
    print(f"Missing chars: {missing_chars}")

    if missing_examples:
        print("")
        print("Missing examples:")
        for item in missing_examples:
            print(f"- {item}")


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument("--page", required=True, type=int)
    parser.add_argument("--woff2", required=True)
    parser.add_argument("--layout", required=True)
    parser.add_argument("--words", required=True)

    args = parser.parse_args()

    check_page(
        page_number=args.page,
        woff2_path=args.woff2,
        layout_db_path=args.layout,
        qpc_json_path=args.words,
    )


if __name__ == "__main__":
    main()