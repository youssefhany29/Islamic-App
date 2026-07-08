import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/qpc_mushaf_repository.dart';
import '../data/qpc_page_font_loader.dart';
import '../hiding/quran_hide_mode.dart';
import '../models/qpc_models.dart';
import '../theme/quran_reader_theme.dart';
import '../widgets/qpc_page_content.dart';

enum QpcGeometryProbeMode { boxes, highlight, hide, calibration }

enum QpcGeometryProbeBackgroundMode {
  qpcRender,
  externalWebpImage,
  exportedQpcImage,
  svgGenerated,
}

class QpcGeometryProbePage extends StatefulWidget {
  const QpcGeometryProbePage({super.key});

  static const List<int> probePages = <int>[2, 3, 56, 255, 604];

  @override
  State<QpcGeometryProbePage> createState() => _QpcGeometryProbePageState();
}

class _QpcGeometryProbePageState extends State<QpcGeometryProbePage> {
  int _selectedPage = 56;
  QpcAyahKey? _selectedAyah;
  QpcGeometryProbeMode _mode = QpcGeometryProbeMode.boxes;
  QpcGeometryProbeBackgroundMode _backgroundMode =
      QpcGeometryProbeBackgroundMode.qpcRender;
  final GlobalKey _qpcRenderBoundaryKey = GlobalKey();
  Future<QpcGeometryProbeResult>? _geometryFuture;
  int? _geometryFuturePage;
  Size? _geometryFutureSize;
  bool? _geometryFutureLargeScreen;
  String? _exportedQpcImagePath;
  int? _exportedQpcImagePage;
  Size? _exportedQpcImagePixelSize;
  bool _exportingQpcImage = false;
  final Map<int, double> _calibrationLeftOverrides = <int, double>{};
  final Map<int, double> _calibrationRightOverrides = <int, double>{};

  @override
  Widget build(BuildContext context) {
    const QuranReaderTheme readerTheme = QuranReaderTheme.classicCream;

    return Scaffold(
      backgroundColor: const Color(0xff151515),
      appBar: AppBar(title: Text('QPC geometry probe - page $_selectedPage')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = math.min(constraints.maxWidth, 430.0);
            final double maxHeight = constraints.maxHeight;
            final double pageWidth = maxWidth;
            final double pageHeight = math.min(maxHeight, pageWidth * 1.62);
            final Size pageSize = Size(pageWidth, pageHeight);

            return FutureBuilder<QpcGeometryProbeResult>(
              future: _futureFor(
                pageSize: pageSize,
                isLargeScreen: MediaQuery.sizeOf(context).width >= 600,
              ),
              builder: (context, snapshot) {
                final QpcGeometryProbeResult? result = snapshot.data;

                if (snapshot.connectionState != ConnectionState.done ||
                    result == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final QpcGeometryPage activeGeometry = _activeGeometryFor(
                  result,
                );
                final double activePageHeight =
                    _backgroundMode == QpcGeometryProbeBackgroundMode.svgGenerated
                    ? math.min(
                        maxHeight,
                        pageWidth *
                            (activeGeometry.imageHeight /
                                activeGeometry.imageWidth),
                      )
                    : pageHeight;
                final Size activePageSize = Size(pageWidth, activePageHeight);
                final Color overlayMaskColor =
                    _backgroundMode ==
                        QpcGeometryProbeBackgroundMode.svgGenerated
                    ? Colors.white
                    : readerTheme.pageBackground;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
                      child: _ProbeSummaryBar(
                        geometry: activeGeometry,
                        selectedPage: _selectedPage,
                        selectedAyah: _selectedAyah,
                        mode: _mode,
                        backgroundMode: _backgroundMode,
                        isExporting: _exportingQpcImage,
                        exportedImagePath: _exportedQpcImagePath,
                        exportedImagePixelSize: _exportedQpcImagePixelSize,
                        calibrationLeft:
                            _calibrationLeftOverrides[_selectedPage] ?? 0,
                        calibrationRight:
                            _calibrationRightOverrides[_selectedPage] ?? 0,
                        onPageChanged: _changePage,
                        onModeChanged: (mode) {
                          setState(() {
                            _mode = mode;
                          });
                        },
                        onBackgroundModeChanged: (mode) {
                          setState(() {
                            _backgroundMode = mode;
                          });
                        },
                        onPrintJson: () {
                          _debugPrintLong(activeGeometry.prettyJson);
                        },
                        onExportQpcImage: _exportCurrentQpcPageImage,
                        onCalibrationChanged: _updateCalibrationOverride,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: activePageSize.width,
                          height: activePageSize.height,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final QpcAyahKey? hit = activeGeometry.hitTest(
                                details.localPosition,
                                activePageSize,
                              );

                              setState(() {
                                _selectedAyah = hit;
                              });

                              _debugPrintTapResult(
                                geometry: activeGeometry,
                                hit: hit,
                                localPosition: details.localPosition,
                              );
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _ProbePageBackground(
                                    result: result,
                                    readerTheme: readerTheme,
                                    mode: _backgroundMode,
                                    qpcRenderBoundaryKey: _qpcRenderBoundaryKey,
                                    exportedImagePath: _exportedQpcImagePath,
                                    exportedImagePage: _exportedQpcImagePage,
                                  ),
                                ),
                                if (_backgroundMode ==
                                        QpcGeometryProbeBackgroundMode
                                            .externalWebpImage &&
                                    !result.hasWebpImage)
                                  const Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    child: _ProbeImageMessageBanner(
                                      message:
                                          'External WebP missing for this page. Showing QPC Render fallback.',
                                    ),
                                  ),
                                if (_backgroundMode ==
                                        QpcGeometryProbeBackgroundMode
                                            .exportedQpcImage &&
                                    !_hasExportedImageForCurrentPage)
                                  const Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    child: _ProbeImageMessageBanner(
                                      message:
                                          'No exported QPC image for this page yet. Showing QPC Render fallback.',
                                    ),
                                  ),
                                if (_backgroundMode ==
                                        QpcGeometryProbeBackgroundMode
                                            .svgGenerated &&
                                    (result.svgGeometry == null ||
                                        !result.hasSvgGeneratedImage))
                                  const Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    child: _ProbeImageMessageBanner(
                                      message:
                                          'SVG Generated assets exist for page 56 only. Showing QPC Render fallback.',
                                    ),
                                  ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _QpcGeometryPainter(
                                      geometry: activeGeometry,
                                      selectedAyah: _selectedAyah,
                                      mode: _mode,
                                      pageBackground: overlayMaskColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
                      child: Text(
                        'WebP target: assets/quran/qpc_pages/'
                        'p${_selectedPage.toString().padLeft(3, '0')}.webp. '
                        'The current background is the live QPC render so the '
                        'overlay can be compared against the exact text layout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool get _hasExportedImageForCurrentPage {
    final String? path = _exportedQpcImagePath;
    return path != null &&
        _exportedQpcImagePage == _selectedPage &&
        File(path).existsSync();
  }

  QpcGeometryPage _activeGeometryFor(QpcGeometryProbeResult result) {
    if (_backgroundMode == QpcGeometryProbeBackgroundMode.svgGenerated &&
        result.svgGeometry != null) {
      return result.svgGeometry!;
    }

    return result.geometry;
  }

  Future<QpcGeometryProbeResult> _futureFor({
    required Size pageSize,
    required bool isLargeScreen,
  }) {
    if (_geometryFuture == null ||
        _geometryFuturePage != _selectedPage ||
        _geometryFutureSize != pageSize ||
        _geometryFutureLargeScreen != isLargeScreen) {
      _geometryFuturePage = _selectedPage;
      _geometryFutureSize = pageSize;
      _geometryFutureLargeScreen = isLargeScreen;
      _geometryFuture = QpcGeometryGenerator.generatePage(
        pageNumber: _selectedPage,
        pageSize: pageSize,
        isLargeScreen: isLargeScreen,
      );
    }

    return _geometryFuture!;
  }

  void _changePage(int page) {
    if (page == _selectedPage) {
      return;
    }

    setState(() {
      _selectedPage = page;
      _selectedAyah = null;
      _geometryFuture = null;
      _geometryFuturePage = null;
      _geometryFutureSize = null;
      _geometryFutureLargeScreen = null;
    });
  }

  void _updateCalibrationOverride({
    required double left,
    required double right,
  }) {
    setState(() {
      _calibrationLeftOverrides[_selectedPage] = left;
      _calibrationRightOverrides[_selectedPage] = right;
    });

    debugPrint(
      'QPC SVG crop override page=$_selectedPage '
      '"$_selectedPage": {"left": ${left.round()}, "right": ${right.round()}}',
    );
  }

  Future<void> _exportCurrentQpcPageImage() async {
    if (_exportingQpcImage) {
      return;
    }

    setState(() {
      _exportingQpcImage = true;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      final BuildContext? boundaryContext =
          _qpcRenderBoundaryKey.currentContext;
      final RenderObject? renderObject = boundaryContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('QPC geometry export failed: RepaintBoundary not ready.');
        return;
      }

      if (renderObject.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }

      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        image.dispose();
        debugPrint('QPC geometry export failed: PNG byteData is null.');
        return;
      }

      final Directory cacheDirectory = await getTemporaryDirectory();
      final String path =
          '${cacheDirectory.path}${Platform.pathSeparator}'
          'qpc_geometry_probe_p${_selectedPage.toString().padLeft(3, '0')}.png';
      final File outputFile = File(path);

      await outputFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      final Size pixelSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      image.dispose();

      if (!mounted) {
        return;
      }

      setState(() {
        _exportedQpcImagePath = outputFile.path;
        _exportedQpcImagePage = _selectedPage;
        _exportedQpcImagePixelSize = pixelSize;
        _backgroundMode = QpcGeometryProbeBackgroundMode.exportedQpcImage;
      });

      debugPrint(
        'QPC geometry exported image page=$_selectedPage '
        'path=${outputFile.path} '
        'pixels=${pixelSize.width.toInt()}x${pixelSize.height.toInt()}',
      );
    } catch (error, stackTrace) {
      debugPrint('QPC geometry export failed: $error');
      debugPrint('$stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _exportingQpcImage = false;
        });
      }
    }
  }

  void _debugPrintTapResult({
    required QpcGeometryPage geometry,
    required QpcAyahKey? hit,
    required Offset localPosition,
  }) {
    if (hit == null) {
      debugPrint(
        'QPC geometry probe tap p${geometry.page} miss at $localPosition',
      );
      return;
    }

    final QpcGeometryAyah? ayah = geometry.ayahForKey(hit);
    final int segmentCount = ayah?.segments.length ?? 0;
    final int textWordCount = ayah?.textWords.length ?? 0;
    final int ayahNumberCount = ayah?.ayahNumberBoxes.length ?? 0;
    final bool lastWordUsedAsAyahNumber = ayahNumberCount > 0;
    final QpcGeometryWord? ayahNumberWord =
        ayah == null || ayah.ayahNumberBoxes.isEmpty
        ? null
        : ayah.ayahNumberBoxes.last;
    final bool multiLine = ayah == null
        ? false
        : ayah.segments.map((s) => s.line).toSet().length > 1;

    debugPrint(
      'QPC geometry probe tap p${geometry.page} selected '
      '${hit.surah}:${hit.ayah}, '
      'textWordBoxes=$textWordCount, ayahNumberBoxes=$ayahNumberCount, '
      'segments=$segmentCount, multiLine=$multiLine, '
      'lastWordUsedAsAyahNumber=$lastWordUsedAsAyahNumber, '
      'lastWordText="${ayahNumberWord?.text ?? ''}", '
      'lastWordLine=${ayahNumberWord?.line}, '
      'looksMarker=${ayahNumberWord?.looksLikeAyahEndMarker ?? false}, '
      'matchesFinalWordByAyah=${ayahNumberWord?.isFinalWordByAyah ?? false}, '
      'mode=${_mode.name}, at=$localPosition',
    );
  }
}

class QpcGeometryGenerator {
  const QpcGeometryGenerator._();

  static Future<QpcGeometryProbeResult> generatePage({
    required int pageNumber,
    required Size pageSize,
    required bool isLargeScreen,
  }) async {
    final int safePageNumber = pageNumber.clamp(1, 604).toInt();
    final Stopwatch stopwatch = Stopwatch()..start();

    await QpcMushafRepository.instance.initialize();
    await Future.wait(<Future<void>>[
      QpcPageFontLoader.instance.ensureLoaded(safePageNumber),
      QpcMushafRepository.instance.loadPage(safePageNumber).then((_) {}),
    ]);

    final QpcPageData pageData = await QpcMushafRepository.instance.loadPage(
      safePageNumber,
    );
    final String fontFamily = QpcPageFontLoader.familyForPage(safePageNumber);
    final bool hasWebpImage = await _assetExists(
      _webpAssetPath(safePageNumber),
    );
    final bool hasSvgGeneratedImage = await _assetExists(
      _svgGeneratedImageAssetPath(safePageNumber),
    );
    final QpcGeometryPage? svgGeometry = await _loadSvgGeometryIfAvailable(
      safePageNumber,
    );
    final _ProbePageMetrics metrics = _ProbePageMetrics.fromSize(
      width: pageSize.width,
      height: pageSize.height,
      isLargeScreen: isLargeScreen,
    );
    final List<QpcGeometryWord> words = <QpcGeometryWord>[];
    final Map<QpcAyahKey, Map<int, Rect>> ayahLineRects =
        <QpcAyahKey, Map<int, Rect>>{};
    final Map<QpcAyahKey, List<QpcGeometryWord>> wordsByAyah =
        <QpcAyahKey, List<QpcGeometryWord>>{};

    for (int lineNumber = 1; lineNumber <= 15; lineNumber++) {
      final QpcMushafLine? line = pageData.lineByNumber(lineNumber);

      if (line == null ||
          line.words.isEmpty ||
          line.isSurahNameLine ||
          line.isBasmallahLine) {
        continue;
      }

      final _MeasuredLine measuredLine = _measureLine(
        line: line,
        fontFamily: fontFamily,
        metrics: metrics,
        pageSize: pageSize,
        isLargeScreen: isLargeScreen,
        finalWordByAyah: pageData.finalWordByAyah,
      );

      words.addAll(measuredLine.words);

      for (final QpcGeometryWord word in measuredLine.words) {
        final QpcAyahKey ayahKey = QpcAyahKey(
          surah: word.surah,
          ayah: word.ayah,
        );
        wordsByAyah.putIfAbsent(ayahKey, () => <QpcGeometryWord>[]).add(word);
        final Map<int, Rect> rectsByLine = ayahLineRects.putIfAbsent(
          ayahKey,
          () => <int, Rect>{},
        );
        final Rect rect = word.toAbsoluteRect(pageSize);
        final Rect? previous = rectsByLine[word.line];
        rectsByLine[word.line] = previous == null
            ? rect
            : previous.expandToInclude(rect);
      }
    }

    final List<QpcGeometryAyah> ayahs =
        ayahLineRects.entries.map((entry) {
          final List<QpcGeometrySegment> segments = entry.value.entries.map((
            lineEntry,
          ) {
            return QpcGeometrySegment.fromRect(
              rect: lineEntry.value,
              line: lineEntry.key,
              pageSize: pageSize,
            );
          }).toList()..sort((a, b) => a.line.compareTo(b.line));

          final List<QpcGeometryWord> ayahWords = List<QpcGeometryWord>.of(
            wordsByAyah[entry.key] ?? const [],
          )..sort((a, b) => a.word.compareTo(b.word));
          final List<QpcGeometryWord> textWords = ayahWords.length <= 1
              ? <QpcGeometryWord>[]
              : ayahWords.take(ayahWords.length - 1).toList(growable: false);
          final List<QpcGeometryWord> ayahNumberBoxes = ayahWords.isEmpty
              ? <QpcGeometryWord>[]
              : <QpcGeometryWord>[ayahWords.last];

          return QpcGeometryAyah(
            surah: entry.key.surah,
            ayah: entry.key.ayah,
            segments: segments,
            textWords: textWords,
            ayahNumberBoxes: ayahNumberBoxes,
          );
        }).toList()..sort((a, b) {
          final int surahCompare = a.surah.compareTo(b.surah);
          return surahCompare == 0 ? a.ayah.compareTo(b.ayah) : surahCompare;
        });

    final QpcGeometryPage geometry = QpcGeometryPage(
      page: safePageNumber,
      imageWidth: pageSize.width,
      imageHeight: pageSize.height,
      ayahs: ayahs,
      words: words,
    );

    debugPrint(
      'QPC geometry generated p$safePageNumber in '
      '${stopwatch.elapsedMilliseconds}ms, '
      'ayahs=${geometry.ayahs.length}, words=${geometry.words.length}',
    );
    debugPrint('QPC geometry cases: ${geometry.caseSummary}');
    _debugPrintValidationReport(geometry);

    return QpcGeometryProbeResult(
      pageData: pageData,
      geometry: geometry,
      hasWebpImage: hasWebpImage,
      hasSvgGeneratedImage: hasSvgGeneratedImage,
      svgGeometry: svgGeometry,
    );
  }

  static _MeasuredLine _measureLine({
    required QpcMushafLine line,
    required String fontFamily,
    required _ProbePageMetrics metrics,
    required Size pageSize,
    required bool isLargeScreen,
    required Map<QpcAyahKey, int> finalWordByAyah,
  }) {
    final double fontSize = _fontSizeForLine(
      line: line,
      lineHeight: metrics.lineHeight,
      fontScale: 1.0,
      isLargeScreen: isLargeScreen,
    );
    final TextStyle baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.0,
      fontWeight: FontWeight.normal,
    );
    final List<InlineSpan> spans = <InlineSpan>[];
    final List<_WordTextRange> ranges = <_WordTextRange>[];
    int offset = 0;

    for (int index = 0; index < line.words.length; index++) {
      final QpcWord word = line.words[index];
      final bool isLastWordInLine = index == line.words.length - 1;
      final int start = offset;
      final int end = start + word.text.length;
      final String text = isLastWordInLine ? word.text : '${word.text} ';

      spans.add(TextSpan(text: text, style: baseStyle));
      ranges.add(_WordTextRange(word: word, start: start, end: end));
      offset += text.length;
    }

    final TextPainter painter = TextPainter(
      text: TextSpan(style: baseStyle, children: spans),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: 1,
      textWidthBasis: TextWidthBasis.parent,
    )..layout();

    final double lineBoxLeft = metrics.horizontalPadding;
    final double lineBoxWidth =
        pageSize.width - (metrics.horizontalPadding * 2);
    final double lineBoxTop =
        metrics.contentTopOffset + ((line.lineNumber - 1) * metrics.lineHeight);
    final double lineBoxHeight = metrics.lineHeight;
    final Size naturalSize = painter.size;
    final double widthScale = naturalSize.width <= 0
        ? 1.0
        : lineBoxWidth / naturalSize.width;
    final double heightScale = naturalSize.height <= 0
        ? 1.0
        : lineBoxHeight / naturalSize.height;
    final double scale = math.min(1.0, math.min(widthScale, heightScale));
    final double dx =
        lineBoxLeft + ((lineBoxWidth - naturalSize.width * scale) / 2);
    final double dy =
        lineBoxTop + ((lineBoxHeight - naturalSize.height * scale) / 2);
    final List<QpcGeometryWord> words = <QpcGeometryWord>[];

    for (final _WordTextRange range in ranges) {
      final List<TextBox> boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );

      Rect? wordRect;
      for (final TextBox box in boxes) {
        final double left = math.min(box.left, box.right);
        final double right = math.max(box.left, box.right);
        final Rect scaledRect = Rect.fromLTRB(
          dx + (left * scale),
          dy + (box.top * scale),
          dx + (right * scale),
          dy + (box.bottom * scale),
        );
        wordRect = wordRect == null
            ? scaledRect
            : wordRect.expandToInclude(scaledRect);
      }

      if (wordRect == null || wordRect.isEmpty) {
        continue;
      }

      words.add(
        QpcGeometryWord.fromRect(
          word: range.word,
          line: line.lineNumber,
          rect: wordRect,
          pageSize: pageSize,
          isFinalWordByAyah:
              finalWordByAyah[range.word.ayahKey] == range.word.word,
        ),
      );
    }

    return _MeasuredLine(words: words);
  }

  static double _fontSizeForLine({
    required QpcMushafLine line,
    required double lineHeight,
    required double fontScale,
    required bool isLargeScreen,
  }) {
    final int wordCount = line.words.length;
    final bool centered = line.isCentered;

    if (isLargeScreen) {
      if (centered) {
        return (lineHeight * 0.62 * fontScale).clamp(14.0, 22.0).toDouble();
      }
      if (wordCount <= 6) {
        return (lineHeight * 0.66 * fontScale).clamp(14.5, 24.0).toDouble();
      }
      if (wordCount <= 9) {
        return (lineHeight * 0.72 * fontScale).clamp(15.0, 26.0).toDouble();
      }
      return (lineHeight * 0.78 * fontScale).clamp(16.0, 29.0).toDouble();
    }

    if (centered && wordCount <= 6) {
      return (lineHeight * 0.68 * fontScale).clamp(15.0, 25.0).toDouble();
    }
    if (centered && wordCount <= 9) {
      return (lineHeight * 0.72 * fontScale).clamp(15.5, 27.0).toDouble();
    }
    if (wordCount <= 6) {
      return (lineHeight * 0.74 * fontScale).clamp(16.0, 28.0).toDouble();
    }
    if (wordCount <= 9) {
      return (lineHeight * 0.80 * fontScale).clamp(16.0, 30.0).toDouble();
    }
    return (lineHeight * 0.86 * fontScale).clamp(17.0, 33.0).toDouble();
  }

  static void _debugPrintValidationReport(QpcGeometryPage geometry) {
    debugPrint(
      'QPC geometry validation page=${geometry.page}, '
      'totalAyahs=${geometry.ayahs.length}',
    );

    for (final QpcGeometryAyah ayah in geometry.ayahs) {
      final QpcGeometryWord? marker = ayah.ayahNumberBoxes.isEmpty
          ? null
          : ayah.ayahNumberBoxes.last;
      debugPrint(
        'QPC geometry ayah ${ayah.surah}:${ayah.ayah} '
        'textWords=${ayah.textWords.length}, '
        'ayahNumberBoxes=${ayah.ayahNumberBoxes.length}, '
        'lastWordText="${marker?.text ?? ''}", '
        'lastWordLocation="${marker?.location ?? ''}", '
        'lastWordIndex=${marker?.word}, '
        'lastWordLine=${marker?.line}, '
        'looksMarker=${marker?.looksLikeAyahEndMarker ?? false}, '
        'matchesFinalWordByAyah=${marker?.isFinalWordByAyah ?? false}',
      );
    }
  }

  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<QpcGeometryPage?> _loadSvgGeometryIfAvailable(int page) async {
    if (!_svgGeneratedPages.contains(page)) {
      return null;
    }

    try {
      final String jsonText = await rootBundle.loadString(
        _svgGeometryAssetPath(page),
      );
      return QpcGeometryPage.fromSvgGeometryJson(
        jsonDecode(jsonText) as Map<String, Object?>,
      );
    } catch (error) {
      debugPrint('QPC SVG geometry load failed p$page: $error');
      return null;
    }
  }
}

class QpcGeometryProbeResult {
  const QpcGeometryProbeResult({
    required this.pageData,
    required this.geometry,
    required this.hasWebpImage,
    required this.hasSvgGeneratedImage,
    required this.svgGeometry,
  });

  final QpcPageData pageData;
  final QpcGeometryPage geometry;
  final bool hasWebpImage;
  final bool hasSvgGeneratedImage;
  final QpcGeometryPage? svgGeometry;
}

class _ProbePageBackground extends StatelessWidget {
  const _ProbePageBackground({
    required this.result,
    required this.readerTheme,
    required this.mode,
    required this.qpcRenderBoundaryKey,
    required this.exportedImagePath,
    required this.exportedImagePage,
  });

  final QpcGeometryProbeResult result;
  final QuranReaderTheme readerTheme;
  final QpcGeometryProbeBackgroundMode mode;
  final GlobalKey qpcRenderBoundaryKey;
  final String? exportedImagePath;
  final int? exportedImagePage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: qpcRenderBoundaryKey,
          child: _QpcRenderBackground(
            pageData: result.pageData,
            readerTheme: readerTheme,
          ),
        ),
        if (mode == QpcGeometryProbeBackgroundMode.externalWebpImage &&
            result.hasWebpImage)
          Image.asset(
            _webpAssetPath(result.geometry.page),
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        if (mode == QpcGeometryProbeBackgroundMode.exportedQpcImage &&
            exportedImagePath != null &&
            exportedImagePage == result.geometry.page)
          Image.file(
            File(exportedImagePath!),
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        if (mode == QpcGeometryProbeBackgroundMode.svgGenerated &&
            result.hasSvgGeneratedImage &&
            result.svgGeometry != null)
          Image.asset(
            _svgGeneratedImageAssetPath(result.geometry.page),
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}

class _QpcRenderBackground extends StatelessWidget {
  const _QpcRenderBackground({
    required this.pageData,
    required this.readerTheme,
  });

  final QpcPageData pageData;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    return QpcPageContent(
      pageData: pageData,
      readerTheme: readerTheme,
      hideMode: QuranHideMode.visible,
      selection: null,
      activeAudioWord: null,
      onWordTap: (_) {},
    );
  }
}

class _ProbeImageMessageBanner extends StatelessWidget {
  const _ProbeImageMessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class QpcGeometryPage {
  const QpcGeometryPage({
    required this.page,
    required this.imageWidth,
    required this.imageHeight,
    required this.ayahs,
    required this.words,
  });

  final int page;
  final double imageWidth;
  final double imageHeight;
  final List<QpcGeometryAyah> ayahs;
  final List<QpcGeometryWord> words;

  factory QpcGeometryPage.fromSvgGeometryJson(Map<String, Object?> json) {
    final Map<String, Object?> viewBox = (json['viewBox'] as Map)
        .cast<String, Object?>();
    final List<QpcGeometryAyah> ayahs = <QpcGeometryAyah>[];
    final List<QpcGeometryWord> words = <QpcGeometryWord>[];

    for (final Object? rawAyah in json['ayahs'] as List<Object?>) {
      final Map<String, Object?> ayahJson = (rawAyah as Map)
          .cast<String, Object?>();
      final int surah = _jsonInt(ayahJson['surah']);
      final int ayah = _jsonInt(ayahJson['ayah']);
      final List<QpcGeometrySegment> segments =
          (ayahJson['segments'] as List<Object?>).map((rawSegment) {
            final Map<String, Object?> segmentJson = (rawSegment as Map)
                .cast<String, Object?>();
            return QpcGeometrySegment(
              x: _jsonDouble(segmentJson['x']),
              y: _jsonDouble(segmentJson['y']),
              w: _jsonDouble(segmentJson['w']),
              h: _jsonDouble(segmentJson['h']),
              line: _jsonInt(segmentJson['line']),
            );
          }).toList();
      final List<QpcGeometryWord> textWords =
          (ayahJson['textWords'] as List<Object?>).map((rawWord) {
            final Map<String, Object?> wordJson = (rawWord as Map)
                .cast<String, Object?>();
            final QpcGeometryWord word = QpcGeometryWord(
              surah: surah,
              ayah: ayah,
              word: _jsonInt(wordJson['wordIndex']),
              location: '',
              text: wordJson['hafs']?.toString() ?? '',
              x: _jsonDouble(wordJson['x']),
              y: _jsonDouble(wordJson['y']),
              w: _jsonDouble(wordJson['w']),
              h: _jsonDouble(wordJson['h']),
              line: _jsonInt(wordJson['line']),
              isFinalWordByAyah: false,
            );
            words.add(word);
            return word;
          }).toList();
      final List<QpcGeometryWord> ayahNumberBoxes =
          (ayahJson['ayahNumberBoxes'] as List<Object?>).map((rawBox) {
            final Map<String, Object?> boxJson = (rawBox as Map)
                .cast<String, Object?>();
            return QpcGeometryWord(
              surah: surah,
              ayah: ayah,
              word: 0,
              location: '',
              text: '',
              x: _jsonDouble(boxJson['x']),
              y: _jsonDouble(boxJson['y']),
              w: _jsonDouble(boxJson['w']),
              h: _jsonDouble(boxJson['h']),
              line: _jsonInt(boxJson['line']),
              isFinalWordByAyah: true,
            );
          }).toList();

      ayahs.add(
        QpcGeometryAyah(
          surah: surah,
          ayah: ayah,
          segments: segments,
          textWords: textWords,
          ayahNumberBoxes: ayahNumberBoxes,
        ),
      );
    }

    return QpcGeometryPage(
      page: _jsonInt(json['page']),
      imageWidth: _jsonDouble(
        ((json['crop'] as Map?)?.cast<String, Object?>() ?? viewBox)['width'],
      ),
      imageHeight: _jsonDouble(viewBox['height']),
      ayahs: ayahs,
      words: words,
    );
  }

  String get prettyJson {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  String get caseSummary {
    final int multiLineAyahs = ayahs
        .where(
          (ayah) =>
              ayah.segments.map((segment) => segment.line).toSet().length > 1,
        )
        .length;
    final int singleLineAyahs = ayahs.length - multiLineAyahs;
    final Map<int, int> ayahsByLine = <int, int>{};

    for (final QpcGeometryAyah ayah in ayahs) {
      for (final QpcGeometrySegment segment in ayah.segments) {
        ayahsByLine.update(
          segment.line,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final int linesWithMultipleAyahs = ayahsByLine.values
        .where((count) => count > 1)
        .length;

    return 'singleLine=$singleLineAyahs, multiLine=$multiLineAyahs, '
        'linesWithMultipleAyahs=$linesWithMultipleAyahs';
  }

  QpcAyahKey? hitTest(Offset localPosition, Size pageSize) {
    final double nx = (localPosition.dx / pageSize.width).clamp(0.0, 1.0);
    final double ny = (localPosition.dy / pageSize.height).clamp(0.0, 1.0);
    const double slop = 0.006;

    for (final QpcGeometryAyah ayah in ayahs) {
      for (final QpcGeometrySegment segment in ayah.segments) {
        if (nx >= segment.x - slop &&
            nx <= segment.x + segment.w + slop &&
            ny >= segment.y - slop &&
            ny <= segment.y + segment.h + slop) {
          return QpcAyahKey(surah: ayah.surah, ayah: ayah.ayah);
        }
      }
    }

    return null;
  }

  QpcGeometryAyah? ayahForKey(QpcAyahKey key) {
    for (final QpcGeometryAyah ayah in ayahs) {
      if (ayah.surah == key.surah && ayah.ayah == key.ayah) {
        return ayah;
      }
    }

    return null;
  }

  List<QpcGeometryWord> wordsForAyah(QpcAyahKey key) {
    return words
        .where((word) => word.surah == key.surah && word.ayah == key.ayah)
        .toList(growable: false);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'page': page,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
      'words': words.map((word) => word.toJson()).toList(),
    };
  }
}

class QpcGeometryAyah {
  const QpcGeometryAyah({
    required this.surah,
    required this.ayah,
    required this.segments,
    required this.textWords,
    required this.ayahNumberBoxes,
  });

  final int surah;
  final int ayah;
  final List<QpcGeometrySegment> segments;
  final List<QpcGeometryWord> textWords;
  final List<QpcGeometryWord> ayahNumberBoxes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'surah': surah,
      'ayah': ayah,
      'textWords': textWords.map((word) => word.toJson()).toList(),
      'ayahNumberBoxes': ayahNumberBoxes.map((word) => word.toJson()).toList(),
      'segments': segments.map((segment) => segment.toJson()).toList(),
    };
  }
}

class QpcGeometrySegment {
  const QpcGeometrySegment({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.line,
  });

  factory QpcGeometrySegment.fromRect({
    required Rect rect,
    required int line,
    required Size pageSize,
  }) {
    return QpcGeometrySegment(
      x: _normalize(rect.left, pageSize.width),
      y: _normalize(rect.top, pageSize.height),
      w: _normalize(rect.width, pageSize.width),
      h: _normalize(rect.height, pageSize.height),
      line: line,
    );
  }

  final double x;
  final double y;
  final double w;
  final double h;
  final int line;

  Rect toRect(Size pageSize) {
    return Rect.fromLTWH(
      x * pageSize.width,
      y * pageSize.height,
      w * pageSize.width,
      h * pageSize.height,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'x': _round(x),
      'y': _round(y),
      'w': _round(w),
      'h': _round(h),
      'line': line,
    };
  }
}

class QpcGeometryWord {
  const QpcGeometryWord({
    required this.surah,
    required this.ayah,
    required this.word,
    required this.location,
    required this.text,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.line,
    required this.isFinalWordByAyah,
  });

  factory QpcGeometryWord.fromRect({
    required QpcWord word,
    required int line,
    required Rect rect,
    required Size pageSize,
    required bool isFinalWordByAyah,
  }) {
    return QpcGeometryWord(
      surah: word.surah,
      ayah: word.ayah,
      word: word.word,
      location: word.location,
      text: word.text,
      x: _normalize(rect.left, pageSize.width),
      y: _normalize(rect.top, pageSize.height),
      w: _normalize(rect.width, pageSize.width),
      h: _normalize(rect.height, pageSize.height),
      line: line,
      isFinalWordByAyah: isFinalWordByAyah,
    );
  }

  final int surah;
  final int ayah;
  final int word;
  final String location;
  final String text;
  final double x;
  final double y;
  final double w;
  final double h;
  final int line;
  final bool isFinalWordByAyah;

  bool get looksLikeAyahEndMarker {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    return trimmed.runes.length <= 2;
  }

  Rect toAbsoluteRect(Size pageSize) {
    return Rect.fromLTWH(
      x * pageSize.width,
      y * pageSize.height,
      w * pageSize.width,
      h * pageSize.height,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'surah': surah,
      'ayah': ayah,
      'word': word,
      'location': location,
      'text': text,
      'looksLikeAyahEndMarker': looksLikeAyahEndMarker,
      'isFinalWordByAyah': isFinalWordByAyah,
      'x': _round(x),
      'y': _round(y),
      'w': _round(w),
      'h': _round(h),
      'line': line,
    };
  }
}

class _QpcGeometryPainter extends CustomPainter {
  const _QpcGeometryPainter({
    required this.geometry,
    required this.selectedAyah,
    required this.mode,
    required this.pageBackground,
  });

  final QpcGeometryPage geometry;
  final QpcAyahKey? selectedAyah;
  final QpcGeometryProbeMode mode;
  final Color pageBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == QpcGeometryProbeMode.boxes ||
        mode == QpcGeometryProbeMode.calibration) {
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
          canvas.drawRect(
            word.toAbsoluteRect(size).inflate(1.0),
            textWordPaint,
          );
        }
        for (final QpcGeometryWord word in ayah.ayahNumberBoxes) {
          final Rect rect = word.toAbsoluteRect(size).inflate(2.0);
          canvas.drawRect(rect, ayahNumberFillPaint);
          canvas.drawRect(rect, ayahNumberPaint);
        }
      }
    }

    if (selectedAyah == null) {
      return;
    }

    if (mode == QpcGeometryProbeMode.hide) {
      _paintHideMask(canvas, size);
      return;
    }

    if (mode != QpcGeometryProbeMode.highlight) {
      return;
    }

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x55F59E0B);
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFF59E0B);

    for (final QpcGeometryAyah ayah in geometry.ayahs) {
      if (ayah.surah != selectedAyah!.surah ||
          ayah.ayah != selectedAyah!.ayah) {
        continue;
      }

      for (final QpcGeometrySegment segment in ayah.segments) {
        final RRect rect = RRect.fromRectAndRadius(
          segment.toRect(size).inflate(2.0),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  void _paintHideMask(Canvas canvas, Size size) {
    final QpcGeometryAyah? ayah = geometry.ayahForKey(selectedAyah!);
    final List<QpcGeometryWord> textWords = ayah?.textWords ?? const [];
    if (textWords.isEmpty) {
      return;
    }

    final Paint maskPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pageBackground;
    final Paint edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0xFFBFAE8A);

    for (final QpcGeometryWord word in textWords) {
      final Rect rect = word.toAbsoluteRect(size).inflate(2.5);
      final RRect roundedMask = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(2),
      );
      canvas.drawRRect(roundedMask, maskPaint);
      canvas.drawRRect(roundedMask, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QpcGeometryPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.selectedAyah != selectedAyah ||
        oldDelegate.mode != mode ||
        oldDelegate.pageBackground != pageBackground;
  }
}

class _ProbeSummaryBar extends StatelessWidget {
  const _ProbeSummaryBar({
    required this.geometry,
    required this.selectedPage,
    required this.selectedAyah,
    required this.mode,
    required this.backgroundMode,
    required this.isExporting,
    required this.exportedImagePath,
    required this.exportedImagePixelSize,
    required this.calibrationLeft,
    required this.calibrationRight,
    required this.onPageChanged,
    required this.onModeChanged,
    required this.onBackgroundModeChanged,
    required this.onPrintJson,
    required this.onExportQpcImage,
    required this.onCalibrationChanged,
  });

  final QpcGeometryPage geometry;
  final int selectedPage;
  final QpcAyahKey? selectedAyah;
  final QpcGeometryProbeMode mode;
  final QpcGeometryProbeBackgroundMode backgroundMode;
  final bool isExporting;
  final String? exportedImagePath;
  final Size? exportedImagePixelSize;
  final double calibrationLeft;
  final double calibrationRight;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<QpcGeometryProbeMode> onModeChanged;
  final ValueChanged<QpcGeometryProbeBackgroundMode> onBackgroundModeChanged;
  final VoidCallback onPrintJson;
  final VoidCallback onExportQpcImage;
  final void Function({required double left, required double right})
  onCalibrationChanged;

  @override
  Widget build(BuildContext context) {
    final String selectedText = selectedAyah == null
        ? 'tap an ayah'
        : 'selected ${selectedAyah!.surah}:${selectedAyah!.ayah}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'p${geometry.page} | ayahs ${geometry.ayahs.length} | '
                    'words ${geometry.words.length} | $selectedText',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: onPrintJson,
                  icon: const Icon(Icons.data_object_rounded, size: 18),
                  label: const Text('JSON'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isExporting ? null : onExportQpcImage,
                icon: Icon(
                  isExporting
                      ? Icons.hourglass_top_rounded
                      : Icons.download_rounded,
                  size: 18,
                ),
                label: Text(
                  isExporting
                      ? 'Exporting current QPC page image...'
                      : 'Export current QPC page image',
                ),
              ),
            ),
            if (exportedImagePath != null && exportedImagePixelSize != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Exported PNG: '
                  '${exportedImagePixelSize!.width.toInt()}x'
                  '${exportedImagePixelSize!.height.toInt()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            const SizedBox(height: 8),
            _ProbePageSelector(
              selectedPage: selectedPage,
              onChanged: onPageChanged,
            ),
            const SizedBox(height: 8),
            _ProbeBackgroundSelector(
              mode: backgroundMode,
              onChanged: onBackgroundModeChanged,
            ),
            const SizedBox(height: 8),
            _ProbeModeSelector(mode: mode, onChanged: onModeChanged),
            if (mode == QpcGeometryProbeMode.hide)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Hide masks textWords only and keeps ayahNumberBoxes visible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            if (mode == QpcGeometryProbeMode.calibration)
              _SvgCropCalibrationPanel(
                page: selectedPage,
                left: calibrationLeft,
                right: calibrationRight,
                onChanged: onCalibrationChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProbeModeSelector extends StatelessWidget {
  const _ProbeModeSelector({required this.mode, required this.onChanged});

  final QpcGeometryProbeMode mode;
  final ValueChanged<QpcGeometryProbeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QpcGeometryProbeMode>(
      segments: const [
        ButtonSegment(
          value: QpcGeometryProbeMode.boxes,
          icon: Icon(Icons.grid_on_rounded, size: 16),
          label: Text('Boxes'),
        ),
        ButtonSegment(
          value: QpcGeometryProbeMode.highlight,
          icon: Icon(Icons.highlight_rounded, size: 16),
          label: Text('Highlight'),
        ),
        ButtonSegment(
          value: QpcGeometryProbeMode.hide,
          icon: Icon(Icons.visibility_off_rounded, size: 16),
          label: Text('Hide'),
        ),
        ButtonSegment(
          value: QpcGeometryProbeMode.calibration,
          icon: Icon(Icons.tune_rounded, size: 16),
          label: Text('Calibration'),
        ),
      ],
      selected: <QpcGeometryProbeMode>{mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _SvgCropCalibrationPanel extends StatelessWidget {
  const _SvgCropCalibrationPanel({
    required this.page,
    required this.left,
    required this.right,
    required this.onChanged,
  });

  final int page;
  final double left;
  final double right;
  final void Function({required double left, required double right}) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          _CalibrationSlider(
            label: 'Left',
            value: left,
            onChanged: (value) => onChanged(left: value, right: right),
          ),
          _CalibrationSlider(
            label: 'Right',
            value: right,
            onChanged: (value) => onChanged(left: left, right: value),
          ),
          Text(
            '"$page": {"left": ${left.round()}, "right": ${right.round()}}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          const Text(
            'Rerun tools/qpc_svg_poc/generate_cropped_svg_pages.py to bake these values into image + geometry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CalibrationSlider extends StatelessWidget {
  const _CalibrationSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            '$label ${value.round()}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: -24,
            max: 24,
            divisions: 48,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ProbeBackgroundSelector extends StatelessWidget {
  const _ProbeBackgroundSelector({required this.mode, required this.onChanged});

  final QpcGeometryProbeBackgroundMode mode;
  final ValueChanged<QpcGeometryProbeBackgroundMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QpcGeometryProbeBackgroundMode>(
      segments: const [
        ButtonSegment(
          value: QpcGeometryProbeBackgroundMode.qpcRender,
          icon: Icon(Icons.text_fields_rounded, size: 16),
          label: Text('QPC Render'),
        ),
        ButtonSegment(
          value: QpcGeometryProbeBackgroundMode.externalWebpImage,
          icon: Icon(Icons.image_rounded, size: 16),
          label: Text('External WebP'),
        ),
        ButtonSegment(
          value: QpcGeometryProbeBackgroundMode.exportedQpcImage,
          icon: Icon(Icons.photo_library_rounded, size: 16),
          label: Text('Exported QPC'),
        ),
        ButtonSegment(
          value: QpcGeometryProbeBackgroundMode.svgGenerated,
          icon: Icon(Icons.polyline_rounded, size: 16),
          label: Text('SVG Generated'),
        ),
      ],
      selected: <QpcGeometryProbeBackgroundMode>{mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _ProbePageSelector extends StatelessWidget {
  const _ProbePageSelector({
    required this.selectedPage,
    required this.onChanged,
  });

  final int selectedPage;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Page',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: selectedPage,
            dropdownColor: const Color(0xff242424),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: QpcGeometryProbePage.probePages.map((page) {
              return DropdownMenuItem<int>(
                value: page,
                child: Text('Page $page'),
              );
            }).toList(),
            onChanged: (page) {
              if (page != null) {
                onChanged(page);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ProbePageMetrics {
  const _ProbePageMetrics({
    required this.horizontalPadding,
    required this.contentTopOffset,
    required this.contentBottomOffset,
    required this.lineHeight,
  });

  final double horizontalPadding;
  final double contentTopOffset;
  final double contentBottomOffset;
  final double lineHeight;

  static _ProbePageMetrics fromSize({
    required double width,
    required double height,
    required bool isLargeScreen,
  }) {
    final double horizontalPadding = _horizontalPaddingForWidth(
      width,
      isLargeScreen: isLargeScreen,
    );
    final double contentTopOffset = _topOffsetForHeight(
      height,
      isLargeScreen: isLargeScreen,
    );
    final double contentBottomOffset = _bottomOffsetForHeight(
      height,
      isLargeScreen: isLargeScreen,
    );
    final double lineHeight =
        (height - contentTopOffset - contentBottomOffset) / 15.0;

    return _ProbePageMetrics(
      horizontalPadding: horizontalPadding,
      contentTopOffset: contentTopOffset,
      contentBottomOffset: contentBottomOffset,
      lineHeight: lineHeight,
    );
  }

  static double _horizontalPaddingForWidth(
    double width, {
    required bool isLargeScreen,
  }) {
    if (isLargeScreen) {
      if (width <= 620) return 16;
      if (width <= 760) return 22;
      return 30;
    }
    if (width <= 330) return 10.w;
    if (width <= 390) return 12.w;
    if (width <= 460) return 14.w;
    return 18.w;
  }

  static double _topOffsetForHeight(
    double height, {
    required bool isLargeScreen,
  }) {
    if (isLargeScreen) {
      return height <= 720 ? 34 : 38;
    }
    if (height <= 650) return 30.h;
    if (height <= 760) return 34.h;
    return 38.h;
  }

  static double _bottomOffsetForHeight(
    double height, {
    required bool isLargeScreen,
  }) {
    if (isLargeScreen) {
      return height <= 720 ? 26 : 30;
    }
    if (height <= 650) return 24.h;
    if (height <= 760) return 28.h;
    return 32.h;
  }
}

class _MeasuredLine {
  const _MeasuredLine({required this.words});

  final List<QpcGeometryWord> words;
}

class _WordTextRange {
  const _WordTextRange({
    required this.word,
    required this.start,
    required this.end,
  });

  final QpcWord word;
  final int start;
  final int end;
}

double _normalize(double value, double size) {
  return (value / size).clamp(0.0, 1.0).toDouble();
}

double _round(double value) {
  return double.parse(value.toStringAsFixed(6));
}

void _debugPrintLong(String text) {
  const int chunkSize = 900;
  for (int start = 0; start < text.length; start += chunkSize) {
    final int end = math.min(start + chunkSize, text.length);
    debugPrint(text.substring(start, end));
  }
}

String _webpAssetPath(int page) {
  return 'assets/quran/qpc_pages/p${page.toString().padLeft(3, '0')}.webp';
}

String _svgGeneratedImageAssetPath(int page) {
  return 'assets/quran/svg_pages/p${page.toString().padLeft(3, '0')}_no_hizb_cropped.png';
}

String _svgGeometryAssetPath(int page) {
  return 'assets/quran/svg_geometry/page_${page.toString().padLeft(3, '0')}_no_hizb_cropped_geometry.json';
}

const Set<int> _svgGeneratedPages = <int>{3, 56, 255, 604};

int _jsonInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.parse(value.toString());
}

double _jsonDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.parse(value.toString());
}
