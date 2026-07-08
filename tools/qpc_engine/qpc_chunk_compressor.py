import argparse
import gzip
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple


def format_kb(size: int) -> str:
    return f"{size / 1024:.2f} KB"


def format_mb(size: int) -> str:
    return f"{size / (1024 * 1024):.2f} MB"


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
        raise ValueError("No valid pages selected.")

    return cleaned


def read_gzip_json(path: Path) -> Any:
    if not path.exists():
        raise FileNotFoundError(path)

    with gzip.open(path, "rb") as file:
        return json.loads(file.read().decode("utf-8"))


def write_gzip_json(path: Path, value: Any, compresslevel: int = 9) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)

    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    with gzip.open(path, "wb", compresslevel=compresslevel) as file:
        file.write(raw)

    return path.stat().st_size


def write_brotli_json(path: Path, value: Any, quality: int = 11) -> int:
    try:
        import brotli
    except ImportError as error:
        raise RuntimeError(
            "brotli is not installed. Run: python -m pip install brotli"
        ) from error

    path.parent.mkdir(parents=True, exist_ok=True)

    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    compressed = brotli.compress(raw, quality=quality)

    path.write_bytes(compressed)

    return path.stat().st_size


def chunk_pages(pages: List[int], chunk_size: int) -> List[List[int]]:
    chunks: List[List[int]] = []

    for index in range(0, len(pages), chunk_size):
        chunks.append(pages[index:index + chunk_size])

    return chunks


def build_chunk_payload(
    *,
    pages_dir: Path,
    pages: List[int],
    strip_debug: bool,
) -> Dict[str, Any]:
    pages_payload: Dict[str, Any] = {}

    for page in pages:
        page_path = pages_dir / f"page_{page:03}.json.gz"
        page_data = read_gzip_json(page_path)

        if strip_debug:
            # اختياري: نحذف حاجات لا نحتاجها في الرندر.
            # لا نحذف svgs ولا lines.
            page_data.pop("kind", None)
            page_data.pop("tc", None)

            for line in page_data.get("lines", []):
                line.pop("first", None)
                line.pop("last", None)

                for word in line.get("words", []):
                    # نخلي id/s/a/w/g عشان التحديد كلمة بكلمة.
                    word.pop("t", None)
                    word.pop("loc", None)

        pages_payload[str(page)] = page_data

    return {
        "v": 1,
        "kind": "qpc_svg_chunk",
        "from": pages[0],
        "to": pages[-1],
        "count": len(pages),
        "pages": pages_payload,
    }


def compress_chunks(
    *,
    pages_dir: Path,
    out_dir: Path,
    pages: List[int],
    chunk_size: int,
    strip_debug: bool,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    chunks = chunk_pages(pages, chunk_size)

    separate_total = 0
    gzip_total = 0
    brotli_total = 0

    report_chunks: List[Dict[str, Any]] = []

    for chunk in chunks:
        for page in chunk:
            separate_total += (pages_dir / f"page_{page:03}.json.gz").stat().st_size

        payload = build_chunk_payload(
            pages_dir=pages_dir,
            pages=chunk,
            strip_debug=strip_debug,
        )

        first_page = chunk[0]
        last_page = chunk[-1]

        gzip_path = out_dir / f"chunk_{first_page:03}_{last_page:03}.json.gz"
        brotli_path = out_dir / f"chunk_{first_page:03}_{last_page:03}.json.br"

        gzip_size = write_gzip_json(gzip_path, payload, compresslevel=9)
        brotli_size = write_brotli_json(brotli_path, payload, quality=11)

        gzip_total += gzip_size
        brotli_total += brotli_size

        report_chunks.append(
            {
                "from": first_page,
                "to": last_page,
                "pages": len(chunk),
                "gzipBytes": gzip_size,
                "brotliBytes": brotli_size,
            }
        )

        print(
            f"chunk {first_page:03}-{last_page:03} | "
            f"gzip={format_kb(gzip_size)} | "
            f"brotli={format_kb(brotli_size)}"
        )

    gzip_saved = separate_total - gzip_total
    brotli_saved = separate_total - brotli_total

    report = {
        "version": 1,
        "kind": "qpc_svg_chunk_compression_report",
        "pagesCount": len(pages),
        "chunkSize": chunk_size,
        "stripDebug": strip_debug,
        "separateGzipBytes": separate_total,
        "chunkedGzipBytes": gzip_total,
        "chunkedBrotliBytes": brotli_total,
        "gzipSavedBytes": gzip_saved,
        "brotliSavedBytes": brotli_saved,
        "gzipSavedPercent": (gzip_saved / separate_total * 100) if separate_total else 0,
        "brotliSavedPercent": (brotli_saved / separate_total * 100) if separate_total else 0,
        "chunks": report_chunks,
    }

    report_path = out_dir / "chunk_compression_report.json"
    report_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print("")
    print("Done ✅")
    print(f"Pages: {len(pages)}")
    print(f"Chunk size: {chunk_size}")
    print(f"Separate page gzip total: {format_mb(separate_total)}")
    print(f"Chunked gzip total: {format_mb(gzip_total)}")
    print(f"Chunked brotli total: {format_mb(brotli_total)}")
    print(f"Gzip saved: {format_mb(gzip_saved)} ({report['gzipSavedPercent']:.2f}%)")
    print(f"Brotli saved: {format_mb(brotli_saved)} ({report['brotliSavedPercent']:.2f}%)")
    print(f"Report: {report_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compress QPC SVG page packs into larger chunks."
    )

    parser.add_argument("--pages-dir", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--pages", default="all")
    parser.add_argument("--chunk-size", type=int, default=20)
    parser.add_argument("--strip-debug", action="store_true")

    args = parser.parse_args()

    pages_dir = Path(args.pages_dir)
    out_dir = Path(args.out_dir)
    pages = parse_pages(args.pages)

    if args.chunk_size <= 0:
        raise ValueError("chunk-size must be greater than 0")

    compress_chunks(
        pages_dir=pages_dir,
        out_dir=out_dir,
        pages=pages,
        chunk_size=args.chunk_size,
        strip_debug=args.strip_debug,
    )


if __name__ == "__main__":
    main()