import 'package:flutter/material.dart';

import '../hiding/quran_hide_mode.dart';
import '../models/qpc_models.dart';
import '../models/quran_ayah_tap_result.dart';
import '../models/quran_selection.dart';
import '../theme/quran_reader_theme.dart';
import 'svg_mushaf_geometry_models.dart';
import 'svg_mushaf_geometry_repository.dart';
import 'svg_mushaf_overlay_painter.dart';
import 'svg_mushaf_page_layout.dart';

class SvgImageMushafPage extends StatefulWidget {
  const SvgImageMushafPage({
    super.key,
    required this.pageNumber,
    required this.isCurrentPage,
    required this.cachedPage,
    required this.loadPageData,
    required this.readerTheme,
    required this.hideMode,
    required this.waqfHighlightEnabled,
    required this.selection,
    required this.activeAudioWord,
    required this.onWordTap,
    required this.onToggleControls,
    required this.onPageLongPress,
    required this.onPageDataReady,
  });

  final int pageNumber;
  final bool isCurrentPage;
  final QpcPageData? cachedPage;
  final Future<QpcPageData> Function(int pageNumber) loadPageData;
  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final bool waqfHighlightEnabled;
  final QuranSelection? selection;
  final QpcWordKey? activeAudioWord;
  final ValueChanged<QpcLineTapResult> onWordTap;
  final VoidCallback onToggleControls;
  final VoidCallback onPageLongPress;
  final ValueChanged<QpcPageData> onPageDataReady;

  @override
  State<SvgImageMushafPage> createState() => _SvgImageMushafPageState();
}

class _SvgImageMushafPageState extends State<SvgImageMushafPage>
    with AutomaticKeepAliveClientMixin {
  final SvgMushafGeometryRepository _geometryRepository =
      SvgMushafGeometryRepository.instance;

  Future<SvgPageGeometry>? _geometryFuture;
  Future<QpcPageData>? _pageDataFuture;
  SvgPageGeometry? _geometry;
  QpcPageData? _pageData;
  int? _notifiedCurrentPageNumber;
  int _loadToken = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageData = widget.cachedPage;
    _ensureFutures();
  }

  @override
  void didUpdateWidget(covariant SvgImageMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pageNumber != widget.pageNumber) {
      _geometry = null;
      _pageData = widget.cachedPage;
      _geometryFuture = null;
      _pageDataFuture = null;
      _notifiedCurrentPageNumber = null;
      _ensureFutures();
      return;
    }

    if (_pageData == null && widget.cachedPage != null) {
      _pageData = widget.cachedPage;
    }

    if (widget.isCurrentPage && !oldWidget.isCurrentPage && _pageData != null) {
      _notifyPageReadyIfCurrent(_pageData!);
    }
  }

  void _ensureFutures() {
    final int token = ++_loadToken;

    _geometryFuture ??= _geometryRepository.loadPage(widget.pageNumber);
    _geometryFuture!.then((SvgPageGeometry geometry) {
      if (!mounted ||
          token != _loadToken ||
          geometry.page != widget.pageNumber) {
        return;
      }
      if (_geometry == geometry) {
        return;
      }
      setState(() {
        _geometry = geometry;
      });
    });

    if (_pageData == null) {
      _pageDataFuture ??= widget.loadPageData(widget.pageNumber);
      _pageDataFuture!.then((QpcPageData pageData) {
        if (!mounted ||
            token != _loadToken ||
            pageData.pageNumber != widget.pageNumber) {
          return;
        }
        if (_pageData == pageData) {
          return;
        }
        setState(() {
          _pageData = pageData;
        });
        _notifyPageReadyIfCurrent(pageData);
      });
    }
  }

  void _notifyPageReadyIfCurrent(QpcPageData pageData) {
    if (!widget.isCurrentPage ||
        _notifiedCurrentPageNumber == pageData.pageNumber) {
      return;
    }

    _notifiedCurrentPageNumber = pageData.pageNumber;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onPageDataReady(pageData);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _ensureFutures();

    final SvgPageGeometry? geometry = _geometry;
    final QpcPageData? pageData = _pageData ?? widget.cachedPage;

    if (pageData != null) {
      _notifyPageReadyIfCurrent(pageData);
    }

    if (geometry == null || pageData == null) {
      return ColoredBox(color: widget.readerTheme.pageBackground);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final Size viewportSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final Size imageSize = Size(geometry.imageWidth, geometry.imageHeight);
        final Rect pageRect = calculateDisplayedPageRect(
          viewportSize,
          imageSize,
        );

        SvgGeometryHit? hitForPosition(Offset position) {
          if (!pageRect.contains(position)) {
            return null;
          }

          return geometry.hitTest(
            position - pageRect.topLeft,
            pageRect.size,
            pageData: pageData,
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            widget.onToggleControls();
          },
          onLongPressStart: (details) {
            final SvgGeometryHit? hit = hitForPosition(details.localPosition);
            if (hit == null) {
              return;
            }

            widget.onWordTap(
              QpcLineTapResult(ayahKey: hit.ayahKey, wordKey: hit.wordKey),
            );
          },
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fromRect(
                  rect: pageRect,
                  child: ColoredBox(
                    color: widget.readerTheme.pageBackground,
                    child: Image.asset(
                      _webpAsset(widget.pageNumber),
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.center,
                      color: widget.readerTheme.textColor,
                      colorBlendMode: BlendMode.srcIn,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return _SvgImageError(
                          pageNumber: widget.pageNumber,
                          readerTheme: widget.readerTheme,
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: SvgMushafOverlayPainter(
                      geometry: geometry,
                      imageSize: imageSize,
                      readerTheme: widget.readerTheme,
                      hideMode: widget.hideMode,
                      selection: widget.selection,
                      waqfHighlightEnabled: widget.waqfHighlightEnabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SvgImageError extends StatelessWidget {
  const _SvgImageError({required this.pageNumber, required this.readerTheme});

  final int pageNumber;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: readerTheme.pageBackground,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Text(
        'تعذر تحميل صورة صفحة $pageNumber',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: readerTheme.secondaryTextColor,
        ),
      ),
    );
  }
}

String _webpAsset(int pageNumber) {
  return 'assets/quran/svg_pages_quran_only_webp/p${pageNumber.toString().padLeft(3, '0')}_quran_only_transparent.webp';
}
