import json
from pathlib import Path


INPUT_JSON = Path("assets/hafs_smart_v8.json")
OUTPUT_JSON = Path("assets/quraan/page_ayah_map.json")


PAGE_KEYS = ["page", "page_number", "pageNumber", "page_no", "pageNo"]
SURA_KEYS = ["sura", "surah", "sura_no", "surah_no", "sura_number", "surah_number"]
AYAH_KEYS = ["ayah", "aya", "ayah_no", "aya_no", "ayah_number", "aya_number"]


def find_value(item, keys):
    for key in keys:
        if key in item and item[key] is not None:
            return item[key]
    return None


def to_int(value):
    if value is None:
        return None

    try:
        return int(str(value).strip())
    except ValueError:
        return None


def main():
    if not INPUT_JSON.exists():
        raise FileNotFoundError(f"File not found: {INPUT_JSON}")

    with INPUT_JSON.open("r", encoding="utf-8") as file:
        data = json.load(file)

    quran = data.get("quran")

    if not isinstance(quran, list):
        raise ValueError("Expected assets/hafs_smart_v8.json to contain a 'quran' list.")

    page_starts = []
    seen_pages = set()

    for item in quran:
        if not isinstance(item, dict):
            continue

        page = to_int(find_value(item, PAGE_KEYS))
        sura = to_int(find_value(item, SURA_KEYS))
        ayah = to_int(find_value(item, AYAH_KEYS))

        if page is None or sura is None or ayah is None:
            continue

        if page not in seen_pages:
            page_starts.append({
                "page": page,
                "sura": sura,
                "ayah": ayah,
            })
            seen_pages.add(page)

    page_starts.sort(key=lambda x: x["page"])

    if not page_starts:
        first_item = quran[0] if quran else {}
        print("❌ Could not generate page_ayah_map.json")
        print("First ayah keys are:")
        print(list(first_item.keys()))
        return

    missing_pages = [page for page in range(1, 605) if page not in seen_pages]

    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT_JSON.open("w", encoding="utf-8") as file:
        json.dump(page_starts, file, ensure_ascii=False, indent=2)

    print(f"✅ Generated: {OUTPUT_JSON}")
    print(f"✅ Pages found: {len(page_starts)}")

    if missing_pages:
        print(f"⚠️ Missing pages count: {len(missing_pages)}")
        print(f"Missing pages: {missing_pages[:50]}")
    else:
        print("✅ All 604 pages found")


if __name__ == "__main__":
    main()