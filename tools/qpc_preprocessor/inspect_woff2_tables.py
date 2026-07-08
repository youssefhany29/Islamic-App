import argparse
from pathlib import Path
from fontTools.ttLib import TTFont


def format_kb(value: int) -> str:
    return f"{value / 1024:.2f} KB"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", required=True, help="Path to .woff2 font")
    args = parser.parse_args()

    font_path = Path(args.font)

    if not font_path.exists():
        raise FileNotFoundError(font_path)

    font = TTFont(str(font_path))

    print("Done ✅")
    print(f"Font: {font_path}")
    print("")
    print("Tables:")

    for tag in font.keys():
        try:
            table = font[tag]
            compiled = table.compile(font)
            size = len(compiled)
        except Exception:
            size = 0

        print(f"- {tag}: {format_kb(size)}")

    print("")
    print("Important checks:")
    print(f"Has SVG table: {'SVG ' in font}")
    print(f"Has glyf table: {'glyf' in font}")
    print(f"Has CFF table: {'CFF ' in font}")
    print(f"Has COLR table: {'COLR' in font}")
    print(f"Has CBDT table: {'CBDT' in font}")

    cmap = font.getBestCmap()
    print(f"CMAP chars: {len(cmap)}")

    sample_codepoints = [0xFC41, 0xFC42, 0xFC43, 0xFC44, 0xFC45]

    print("")
    print("Sample cmap:")
    for codepoint in sample_codepoints:
        glyph_name = cmap.get(codepoint)
        print(f"U+{codepoint:04X} -> {glyph_name}")


if __name__ == "__main__":
    main()