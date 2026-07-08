import json
from pathlib import Path

manifest_path = Path(r"..\..\build\qpc_engine_pages_all\manifest.json")
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

for page in manifest["pages"]:
    if page["missingGlyphs"] != 0 or page["missingWords"] != 0:
        print(page)