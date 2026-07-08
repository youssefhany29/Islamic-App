# Image Quality Lab Report

Images tested: 1
Qualities: q80, q85, q90, q95
Resize rule: images wider than 2400px are encoded at 2400px wide; smaller images are not resized.

| Image | Dimensions | Encoded Dimensions | Original Size | q80 Size | q80 Saved | q85 Size | q85 Saved | q90 Size | q90 Saved | q95 Size | q95 Saved | Recommended |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| FridaySunrise.png | 1672x941 | 1672x941 | 1.6 MiB | 55.9 KiB | 96.5% | 71.8 KiB | 95.5% | 103.2 KiB | 93.6% | 177.3 KiB | 89.0% | q90 |

## Notes

- Original files are copied into the output folder for comparison.
- Original app assets are never modified.
- The recommendation is size-based only; inspect `compare.html` before applying compression broadly.