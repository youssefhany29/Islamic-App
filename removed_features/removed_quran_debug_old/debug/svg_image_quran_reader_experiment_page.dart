import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/qpc_models.dart';
import 'qpc_geometry_probe_page.dart';

enum SvgImageReaderInteractionMode { highlight, hide }

enum SvgImageReaderImageSource { webp, png }

enum SvgImageReaderBackground {
  white(Color(0xFFFFFFFF), 'White'),
  warmPaper(Color(0xFFF4ECD8), 'Warm paper'),
  darkTest(Color(0xFF24211B), 'Dark test'),
  debugColor(Color(0xFFDCFCE7), 'Debug');

  const SvgImageReaderBackground(this.color, this.label);

  final Color color;
  final String label;
}

class SvgImageQuranReaderExperimentPage extends StatefulWidget {
  const SvgImageQuranReaderExperimentPage({super.key});

  static final List<int> experimentPages = List<int>.generate(
    604,
    (index) => index + 1,
  );

  @override
  State<SvgImageQuranReaderExperimentPage> createState() =>
      _SvgImageQuranReaderExperimentPageState();
}

class _SvgImageQuranReaderExperimentPageState
    extends State<SvgImageQuranReaderExperimentPage> {
  late final PageController _pageController;
  final Map<int, Future<_SvgReaderPageAsset>> _pageFutures =
      <int, Future<_SvgReaderPageAsset>>{};

  int _currentIndex = 0;
  QpcAyahKey? _selectedAyah;
  SvgImageReaderInteractionMode _mode = SvgImageReaderInteractionMode.highlight;
  SvgImageReaderImageSource _imageSource = SvgImageReaderImageSource.webp;
  SvgImageReaderBackground _background = SvgImageReaderBackground.white;
  bool _showBoxes = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAround(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int currentPage =
        SvgImageQuranReaderExperimentPage.experimentPages[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xff111111),
      appBar: AppBar(
        title: Text('Hybrid SVG Quran Reader Experiment - p$currentPage'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SvgReaderDebugControls(
              mode: _mode,
              imageSource: _imageSource,
              background: _background,
              showBoxes: _showBoxes,
              selectedAyah: _selectedAyah,
              onModeChanged: (mode) {
                setState(() {
                  _mode = mode;
                });
              },
              onImageSourceChanged: (source) {
                setState(() {
                  _imageSource = source;
                });
                _preloadAround(_currentIndex);
              },
              onBackgroundChanged: (background) {
                setState(() {
                  _background = background;
                });
              },
              onShowBoxesChanged: (value) {
                setState(() {
                  _showBoxes = value;
                });
              },
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                allowImplicitScrolling: true,
                itemCount:
                    SvgImageQuranReaderExperimentPage.experimentPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _selectedAyah = null;
                  });
                  _preloadAround(index);
                },
                itemBuilder: (context, index) {
                  final int pageNumber =
                      SvgImageQuranReaderExperimentPage.experimentPages[index];

                  return FutureBuilder<_SvgReaderPageAsset>(
                    future: _loadPage(pageNumber),
                    builder: (context, snapshot) {
                      final _SvgReaderPageAsset? asset = snapshot.data;

                      if (snapshot.connectionState != ConnectionState.done ||
                          asset == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!asset.available) {
                        return _SvgReaderMissingAsset(pageNumber: pageNumber);
                      }

                      return _SvgReaderPageView(
                        asset: asset,
                        imageSource: _imageSource,
                        selectedAyah: index == _currentIndex
                            ? _selectedAyah
                            : null,
                        mode: _mode,
                        backgroundColor: _background.color,
                        showBoxes: _showBoxes,
                        onAyahSelected: (ayahKey) {
                          setState(() {
                            _selectedAyah = ayahKey;
                          });
                          debugPrint(
                            'SVG image reader selected p$pageNumber '
                            '${ayahKey?.toString() ?? 'miss'}',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_SvgReaderPageAsset> _loadPage(int pageNumber) {
    return _pageFutures.putIfAbsent(pageNumber, () async {
      final String pngAsset = _svgPngImageAssetPath(pageNumber);
      final String webpAsset = _svgWebpImageAssetPath(pageNumber);
      final String geometryAsset = _svgGeometryAssetPath(pageNumber);

      try {
        final String geometryText = await rootBundle.loadString(geometryAsset);
        await rootBundle.load(pngAsset);
        bool hasWebpAsset = false;
        try {
          await rootBundle.load(webpAsset);
          hasWebpAsset = true;
        } catch (_) {
          hasWebpAsset = false;
        }
        final QpcGeometryPage geometry = QpcGeometryPage.fromSvgGeometryJson(
          jsonDecode(geometryText) as Map<String, Object?>,
        );

        return _SvgReaderPageAsset(
          pageNumber: pageNumber,
          pngAsset: pngAsset,
          webpAsset: webpAsset,
          hasWebpAsset: hasWebpAsset,
          geometry: geometry,
          available: true,
        );
      } catch (error) {
        debugPrint('SVG image reader missing asset p$pageNumber: $error');
        return _SvgReaderPageAsset(
          pageNumber: pageNumber,
          pngAsset: pngAsset,
          webpAsset: webpAsset,
          hasWebpAsset: false,
          geometry: null,
          available: false,
        );
      }
    });
  }

  void _preloadAround(int index) {
    for (final int nextIndex in <int>[index - 1, index, index + 1]) {
      if (nextIndex < 0 ||
          nextIndex >=
              SvgImageQuranReaderExperimentPage.experimentPages.length) {
        continue;
      }

      final int page =
          SvgImageQuranReaderExperimentPage.experimentPages[nextIndex];
      _loadPage(page).then((asset) {
        if (!mounted || !asset.available) {
          return;
        }

        precacheImage(AssetImage(asset.pngAsset), context);
        if (asset.hasWebpAsset) {
          precacheImage(AssetImage(asset.webpAsset), context);
        }
      });
    }
  }
}

class _SvgReaderPageView extends StatelessWidget {
  const _SvgReaderPageView({
    required this.asset,
    required this.imageSource,
    required this.selectedAyah,
    required this.mode,
    required this.backgroundColor,
    required this.showBoxes,
    required this.onAyahSelected,
  });

  final _SvgReaderPageAsset asset;
  final SvgImageReaderImageSource imageSource;
  final QpcAyahKey? selectedAyah;
  final SvgImageReaderInteractionMode mode;
  final Color backgroundColor;
  final bool showBoxes;
  final ValueChanged<QpcAyahKey?> onAyahSelected;

  @override
  Widget build(BuildContext context) {
    final QpcGeometryPage geometry = asset.geometry!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        final double imageRatio = geometry.imageHeight / geometry.imageWidth;
        double width = maxWidth;
        double height = width * imageRatio;

        if (height > maxHeight) {
          height = maxHeight;
          width = height / imageRatio;
        }

        final Size pageSize = Size(width, height);
        final String imageAsset =
            imageSource == SvgImageReaderImageSource.webp && asset.hasWebpAsset
            ? asset.webpAsset
            : asset.pngAsset;

        return Center(
          child: SizedBox(
            width: pageSize.width,
            height: pageSize.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final QpcAyahKey? hit = geometry.hitTest(
                  details.localPosition,
                  pageSize,
                );
                onAyahSelected(hit);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: backgroundColor,
                    child: Image.asset(imageAsset, fit: BoxFit.fill),
                  ),
                  CustomPaint(
                    painter: _SvgImageReaderOverlayPainter(
                      geometry: geometry,
                      selectedAyah: selectedAyah,
                      mode: mode,
                      maskColor: backgroundColor,
                      showBoxes: showBoxes,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SvgImageReaderOverlayPainter extends CustomPainter {
  const _SvgImageReaderOverlayPainter({
    required this.geometry,
    required this.selectedAyah,
    required this.mode,
    required this.maskColor,
    required this.showBoxes,
  });

  final QpcGeometryPage geometry;
  final QpcAyahKey? selectedAyah;
  final SvgImageReaderInteractionMode mode;
  final Color maskColor;
  final bool showBoxes;

  @override
  void paint(Canvas canvas, Size size) {
    if (showBoxes) {
      _paintBoxes(canvas, size);
    }

    final QpcAyahKey? ayahKey = selectedAyah;
    if (ayahKey == null) {
      return;
    }

    final QpcGeometryAyah? ayah = geometry.ayahForKey(ayahKey);
    if (ayah == null) {
      return;
    }

    if (mode == SvgImageReaderInteractionMode.hide) {
      _paintHide(canvas, size, ayah);
      return;
    }

    _paintHighlight(canvas, size, ayah);
  }

  void _paintBoxes(Canvas canvas, Size size) {
    final Paint segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x553B82F6);
    final Paint textWordPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xCC22C55E);
    final Paint ayahNumberPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE879F9);
    final Paint ayahNumberFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x22E879F9);

    for (final QpcGeometryAyah ayah in geometry.ayahs) {
      for (final QpcGeometrySegment segment in ayah.segments) {
        canvas.drawRect(segment.toRect(size), segmentPaint);
      }

      for (final QpcGeometryWord word in ayah.textWords) {
        canvas.drawRect(word.toAbsoluteRect(size).inflate(1), textWordPaint);
      }

      for (final QpcGeometryWord marker in ayah.ayahNumberBoxes) {
        final Rect rect = marker.toAbsoluteRect(size).inflate(2);
        canvas.drawRect(rect, ayahNumberFillPaint);
        canvas.drawRect(rect, ayahNumberPaint);
      }
    }
  }

  void _paintHighlight(Canvas canvas, Size size, QpcGeometryAyah ayah) {
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x55F59E0B);
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFF59E0B);

    for (final QpcGeometrySegment segment in ayah.segments) {
      final RRect rect = RRect.fromRectAndRadius(
        segment.toRect(size).inflate(2),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, borderPaint);
    }
  }

  void _paintHide(Canvas canvas, Size size, QpcGeometryAyah ayah) {
    final Paint maskPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = maskColor;
    final Paint edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0xFFBFAE8A);

    for (final QpcGeometryWord word in ayah.textWords) {
      final RRect rect = RRect.fromRectAndRadius(
        word.toAbsoluteRect(size).inflate(2.5),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, maskPaint);
      canvas.drawRRect(rect, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SvgImageReaderOverlayPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.selectedAyah != selectedAyah ||
        oldDelegate.mode != mode ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.showBoxes != showBoxes;
  }
}

class _SvgReaderDebugControls extends StatelessWidget {
  const _SvgReaderDebugControls({
    required this.mode,
    required this.imageSource,
    required this.background,
    required this.showBoxes,
    required this.selectedAyah,
    required this.onModeChanged,
    required this.onImageSourceChanged,
    required this.onBackgroundChanged,
    required this.onShowBoxesChanged,
  });

  final SvgImageReaderInteractionMode mode;
  final SvgImageReaderImageSource imageSource;
  final SvgImageReaderBackground background;
  final bool showBoxes;
  final QpcAyahKey? selectedAyah;
  final ValueChanged<SvgImageReaderInteractionMode> onModeChanged;
  final ValueChanged<SvgImageReaderImageSource> onImageSourceChanged;
  final ValueChanged<SvgImageReaderBackground> onBackgroundChanged;
  final ValueChanged<bool> onShowBoxesChanged;

  @override
  Widget build(BuildContext context) {
    final String selectedText = selectedAyah == null
        ? 'Selected: none'
        : 'Selected: ${selectedAyah!.surah}:${selectedAyah!.ayah}';

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xff1F2937)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<SvgImageReaderInteractionMode>(
                    segments: const [
                      ButtonSegment(
                        value: SvgImageReaderInteractionMode.highlight,
                        icon: Icon(Icons.highlight_rounded, size: 16),
                        label: Text('Highlight'),
                      ),
                      ButtonSegment(
                        value: SvgImageReaderInteractionMode.hide,
                        icon: Icon(Icons.visibility_off_rounded, size: 16),
                        label: Text('Hide'),
                      ),
                    ],
                    selected: <SvgImageReaderInteractionMode>{mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      onModeChanged(selection.first);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Boxes',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Switch(value: showBoxes, onChanged: onShowBoxesChanged),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<SvgImageReaderImageSource>(
              segments: const [
                ButtonSegment(
                  value: SvgImageReaderImageSource.webp,
                  label: Text('WebP'),
                ),
                ButtonSegment(
                  value: SvgImageReaderImageSource.png,
                  label: Text('PNG'),
                ),
              ],
              selected: <SvgImageReaderImageSource>{imageSource},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                onImageSourceChanged(selection.first);
              },
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<SvgImageReaderBackground>(
                segments: SvgImageReaderBackground.values
                    .map(
                      (item) =>
                          ButtonSegment(value: item, label: Text(item.label)),
                    )
                    .toList(),
                selected: <SvgImageReaderBackground>{background},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  onBackgroundChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedText,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SvgReaderMissingAsset extends StatelessWidget {
  const _SvgReaderMissingAsset({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Missing SVG generated assets for page $pageNumber',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }
}

class _SvgReaderPageAsset {
  const _SvgReaderPageAsset({
    required this.pageNumber,
    required this.pngAsset,
    required this.webpAsset,
    required this.hasWebpAsset,
    required this.geometry,
    required this.available,
  });

  final int pageNumber;
  final String pngAsset;
  final String webpAsset;
  final bool hasWebpAsset;
  final QpcGeometryPage? geometry;
  final bool available;
}

String _svgPngImageAssetPath(int page) {
  return 'assets/quran/svg_pages/p${page.toString().padLeft(3, '0')}_no_hizb_cropped_transparent.png';
}

String _svgWebpImageAssetPath(int page) {
  return 'assets/quran/svg_pages_webp/p${page.toString().padLeft(3, '0')}_no_hizb_cropped_transparent.webp';
}

String _svgGeometryAssetPath(int page) {
  return 'assets/quran/svg_geometry/pages/page_${page.toString().padLeft(3, '0')}.json';
}
