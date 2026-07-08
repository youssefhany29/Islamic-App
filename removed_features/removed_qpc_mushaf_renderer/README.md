Archived QPC mushaf renderer
============================

These files were moved out of the active Flutter source after the Quran-only
SVG/WebP reader became the only mushaf page renderer.

Archived here:

- `qpc_page_font_loader.dart`
- `qpc_page_content.dart`
- `qpc_line_view.dart`
- `qpc_basmallah_line.dart`
- `qpc_surah_header_line.dart`
- `qpc_text_layout_warm_up.dart`
- `qpc_render_probe.dart`
- `qpc_exact_experiment_page.dart`
- `qpc_page_meta_header.dart`
- `qpc_page_number_badge.dart`
- `qpc_reader_overlay_controls.dart`
- `svg_mushaf_feature_flag.dart`

Kept active even though names still include QPC:

- `qpc_connected_mushaf_page.dart`: current reader container for SVG/WebP,
  audio, tafsir, irab, bookmarks, last read, and settings.
- `qpc_mushaf_page_view.dart`: current RTL PageView container for SVG/WebP.
- `qpc_mushaf_repository.dart`, `qpc_models.dart`: page/word metadata used by
  SVG hit testing, audio word sync, search, tafsir/irab flows, bookmarks, and
  reading progress.

No files were deleted in this cleanup.
