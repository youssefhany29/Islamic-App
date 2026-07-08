import argparse
import urllib.request
from pathlib import Path


def parse_pages(value: str) -> list[int]:
    if value.strip().lower() == "all":
        return list(range(1, 605))

    pages: list[int] = []

    for part in value.split(","):
        part = part.strip()

        if not part:
            continue

        if "-" in part:
            a, b = part.split("-", 1)
            start = int(a.strip())
            end = int(b.strip())

            if start > end:
                start, end = end, start

            pages.extend(range(start, end + 1))
        else:
            pages.append(int(part))

    return sorted(set(page for page in pages if 1 <= page <= 604))


def download_file(url: str, output_path: Path) -> int:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if output_path.exists():
        return output_path.stat().st_size

    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0",
        },
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        data = response.read()

    output_path.write_bytes(data)

    return len(data)


def format_kb(size: int) -> str:
    return f"{size / 1024:.2f} KB"


def format_mb(size: int) -> str:
    return f"{size / (1024 * 1024):.2f} MB"


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--pages",
        required=True,
        help="Examples: 1,100,604 or 1-10 or all",
    )

    parser.add_argument(
        "--theme",
        default="light",
        choices=["light", "dark", "sepia"],
    )

    parser.add_argument(
        "--out-dir",
        required=True,
    )

    args = parser.parse_args()

    pages = parse_pages(args.pages)
    out_dir = Path(args.out_dir)

    base_url = (
        "https://verses.quran.foundation/fonts/quran/hafs/"
        f"v4/ot-svg/{args.theme}/woff2"
    )

    total = 0

    for index, page in enumerate(pages, start=1):
        url = f"{base_url}/p{page}.woff2"
        output_path = out_dir / args.theme / f"p{page}.woff2"

        size = download_file(url, output_path)
        total += size

        print(
            f"[{index}/{len(pages)}] p{page}.woff2 | "
            f"{format_kb(size)} | {url}"
        )

    print("")
    print("Done ✅")
    print(f"Pages: {len(pages)}")
    print(f"Total: {format_mb(total)}")
    print(f"Average: {format_kb(total // len(pages)) if pages else '0 KB'}")
    print(f"Output: {out_dir}")


if __name__ == "__main__":
    main()