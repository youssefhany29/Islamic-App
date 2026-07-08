import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/qpc_mushaf_repository.dart';
import '../data/qpc_reader_perf.dart';
import '../hiding/quran_hide_mode.dart';
import '../models/qpc_models.dart';
import '../models/quran_ayah_tap_result.dart';
import '../models/quran_selection.dart';
import '../svg/svg_image_mushaf_page.dart';
import '../svg/svg_mushaf_geometry_repository.dart';
import '../theme/quran_reader_theme.dart';
import 'qpc_connected_ayah_view.dart';

class QpcMushafPageView extends StatefulWidget {
  const QpcMushafPageView({
    super.key,
    required this.pageController,
    required this.selectedPageNumber,
    required this.readerTheme,
    required this.hideMode,
    required this.waqfHighlightEnabled,
    required this.selection,
    required this.activeAudioWord,
    required this.fontScale,
    required this.connectedMode,
    required this.anchorAyahKey,
    required this.onPageChanged,
    required this.onPagePreviewChanged,
    required this.onWordTap,
    required this.onToggleControls,
    required this.onPageLongPress,
    required this.onPageDataReady,
    required this.onConnectedAnchorChanged,
  });

  final PageController pageController;
  final int selectedPageNumber;
  final QuranReaderTheme readerTheme;
  final QuranHideMode hideMode;
  final bool waqfHighlightEnabled;
  final QuranSelection? selection;
  final QpcWordKey? activeAudioWord;
  final double fontScale;
  final bool connectedMode;
  final QpcAyahKey? anchorAyahKey;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPagePreviewChanged;
  final ValueChanged<QpcLineTapResult> onWordTap;
  final VoidCallback onToggleControls;
  final VoidCallback onPageLongPress;
  final ValueChanged<QpcPageData> onPageDataReady;
  final void Function(QpcAyahKey ayahKey, int pageNumber)
  onConnectedAnchorChanged;

  static const int firstPageNumber = 1;
  static const int totalPages = 604;
  static const int lastPageNumber = firstPageNumber + totalPages - 1;

  static int pageNumberFromIndex(int index) {
    final int safeIndex = index.clamp(0, totalPages - 1).toInt();
    return lastPageNumber - safeIndex;
  }

  static int indexFromPageNumber(int pageNumber) {
    final int safePageNumber = pageNumber
        .clamp(firstPageNumber, lastPageNumber)
        .toInt();
    return lastPageNumber - safePageNumber;
  }

  @override
  State<QpcMushafPageView> createState() => _QpcMushafPageViewState();
}

class _QpcMushafPageViewState extends State<QpcMushafPageView> {
  final QpcMushafRepository _repository = QpcMushafRepository.instance;
  final SvgMushafGeometryRepository _svgGeometryRepository =
      SvgMushafGeometryRepository.instance;

  int? _lastLivePageNumber;
  int? _lastWarmLeadPageNumber;
  int _warmUpGeneration = 0;
  Timer? _leadWarmUpTimer;
  int? _pendingLeadWarmUpPage;
  final Map<int, Future<QpcPageData>> _pageLoadFutures =
      <int, Future<QpcPageData>>{};

  @override
  void initState() {
    super.initState();
    _lastLivePageNumber = widget.selectedPageNumber;
    _startSettledPageWarmUp(widget.selectedPageNumber);
    widget.pageController.addListener(_handleLivePageScroll);
  }

  @override
  void didUpdateWidget(covariant QpcMushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController.removeListener(_handleLivePageScroll);
      widget.pageController.addListener(_handleLivePageScroll);
      _lastLivePageNumber = widget.selectedPageNumber;
    }

    if (oldWidget.selectedPageNumber != widget.selectedPageNumber) {
      _lastLivePageNumber = widget.selectedPageNumber;
      _startSettledPageWarmUp(widget.selectedPageNumber);
    }
  }

  @override
  void dispose() {
    _leadWarmUpTimer?.cancel();
    widget.pageController.removeListener(_handleLivePageScroll);
    super.dispose();
  }

  void _handleLivePageScroll() {
    if (widget.connectedMode || !widget.pageController.hasClients) {
      return;
    }

    final double? rawPage = widget.pageController.page;
    if (rawPage == null) {
      return;
    }

    final int previewPageNumber = _safePageNumber(
      QpcMushafPageView.pageNumberFromIndex(rawPage.round()),
    );

    if (_lastLivePageNumber != previewPageNumber) {
      _lastLivePageNumber = previewPageNumber;
      widget.onPagePreviewChanged(previewPageNumber);
    }

    final int currentPageIndex = QpcMushafPageView.indexFromPageNumber(
      widget.selectedPageNumber,
    );
    final double dragOffset = rawPage - currentPageIndex;

    final int leadPageIndex;
    if (dragOffset > 0.06) {
      leadPageIndex = currentPageIndex + 1;
    } else if (dragOffset < -0.06) {
      leadPageIndex = currentPageIndex - 1;
    } else {
      leadPageIndex = currentPageIndex;
    }

    final int leadPageNumber = _safePageNumber(
      QpcMushafPageView.pageNumberFromIndex(leadPageIndex),
    );

    if (_lastWarmLeadPageNumber == leadPageNumber) {
      return;
    }

    _lastWarmLeadPageNumber = leadPageNumber;
    _scheduleLeadPageWarmUp(leadPageNumber);
  }

  int _safePageNumber(int pageNumber) {
    return pageNumber.clamp(
      QpcMushafPageView.firstPageNumber,
      QpcMushafPageView.totalPages,
    );
  }

  Future<QpcPageData> _loadPageDataForSvgView(int pageNumber) {
    final int safePageNumber = _safePageNumber(pageNumber);
    final QpcPageData? cachedPage = _repository.getCachedPage(safePageNumber);

    if (cachedPage != null) {
      return Future<QpcPageData>.value(cachedPage);
    }

    final Future<QpcPageData>? runningLoad = _pageLoadFutures[safePageNumber];
    if (runningLoad != null) {
      return runningLoad;
    }

    final Future<QpcPageData> task = QpcReaderPerf.timeAsync(
      'svg page data load p$safePageNumber',
      () => _repository.loadPage(safePageNumber),
    );

    _pageLoadFutures[safePageNumber] = task;

    return task.whenComplete(() {
      _pageLoadFutures.remove(safePageNumber);
    });
  }

  void _startSettledPageWarmUp(int pageNumber) {
    final int safePageNumber = _safePageNumber(pageNumber);
    final int generation = ++_warmUpGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _warmUpGeneration) {
        return;
      }
      unawaited(
        _preparePageWindow(
          safePageNumber,
          radius: 2,
          generation: generation,
          reason: 'settled',
          trimCache: true,
        ),
      );
    });
  }

  Future<void> _preparePageWindow(
    int pageNumber, {
    required int radius,
    required int generation,
    required String reason,
    required bool trimCache,
  }) async {
    final int safePageNumber = _safePageNumber(pageNumber);

    await QpcReaderPerf.timeAsync(
      'svg page view warm-up $reason p$safePageNumber r$radius',
      () async {
        for (final int page in _priorityPages(safePageNumber, radius: radius)) {
          if (!mounted || generation != _warmUpGeneration) {
            return;
          }

          await _preparePageCompletely(page);

          if (!mounted || generation != _warmUpGeneration) {
            return;
          }

          await Future<void>.delayed(Duration.zero);
        }
      },
    );

    if (trimCache) {
      _repository.retainPagesAround(safePageNumber, radius: radius + 2);
      _trimPageLoadFuturesAround(safePageNumber, radius: radius + 2);
    }
  }

  Future<void> _preparePageCompletely(int pageNumber) async {
    final int safePageNumber = _safePageNumber(pageNumber);

    await Future.wait(<Future<dynamic>>[
      _repository.loadPage(safePageNumber),
      _svgGeometryRepository.loadPage(safePageNumber),
      _loadSvgImageAssetForWarmUp(safePageNumber),
    ]);
  }

  void _scheduleLeadPageWarmUp(int pageNumber) {
    final int safePageNumber = _safePageNumber(pageNumber);
    if (_isPageReady(safePageNumber)) {
      return;
    }

    _pendingLeadWarmUpPage = safePageNumber;
    _leadWarmUpTimer?.cancel();
    _leadWarmUpTimer = Timer(const Duration(milliseconds: 120), () {
      final int? pendingPage = _pendingLeadWarmUpPage;
      if (!mounted || pendingPage == null || _isPageReady(pendingPage)) {
        return;
      }

      unawaited(
        _preparePageWindow(
          pendingPage,
          radius: 0,
          generation: _warmUpGeneration,
          reason: 'lead',
          trimCache: false,
        ),
      );
    });
  }

  bool _isPageReady(int pageNumber) {
    final int safePageNumber = _safePageNumber(pageNumber);
    return _repository.getCachedPage(safePageNumber) != null &&
        _svgGeometryRepository.getCachedPage(safePageNumber) != null;
  }

  List<int> _priorityPages(int pageNumber, {required int radius}) {
    final int safePageNumber = _safePageNumber(pageNumber);
    final List<int> pages = <int>[safePageNumber];

    for (int offset = 1; offset <= radius; offset++) {
      final int nextPage = safePageNumber + offset;
      final int previousPage = safePageNumber - offset;

      if (nextPage <= QpcMushafPageView.totalPages) {
        pages.add(nextPage);
      }

      if (previousPage >= QpcMushafPageView.firstPageNumber) {
        pages.add(previousPage);
      }
    }

    return pages;
  }

  void _trimPageLoadFuturesAround(int pageNumber, {required int radius}) {
    final int safePageNumber = _safePageNumber(pageNumber);
    final int minPage = _safePageNumber(safePageNumber - radius);
    final int maxPage = _safePageNumber(safePageNumber + radius);

    _pageLoadFutures.removeWhere((page, _) {
      return page < minPage || page > maxPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.connectedMode) {
      return QpcConnectedAyahView(
        readerTheme: widget.readerTheme,
        hideMode: widget.hideMode,
        selection: widget.selection,
        activeAudioWord: widget.activeAudioWord,
        fontScale: widget.fontScale,
        initialPageNumber: widget.selectedPageNumber,
        anchorAyahKey: widget.anchorAyahKey,
        onAyahTap: widget.onWordTap,
        onToggleControls: widget.onToggleControls,
        onPageChanged: widget.onPageChanged,
        onAnchorChanged: widget.onConnectedAnchorChanged,
      );
    }

    return ColoredBox(
      color: widget.readerTheme.pageBackground,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: PageView.builder(
          reverse: false,
          allowImplicitScrolling: true,
          controller: widget.pageController,
          itemCount: QpcMushafPageView.totalPages,
          onPageChanged: (pageIndex) {
            final int pageNumber = QpcMushafPageView.pageNumberFromIndex(
              pageIndex,
            );

            widget.onPageChanged(pageNumber);
          },
          itemBuilder: (context, pageIndex) {
            final int pageNumber = QpcMushafPageView.pageNumberFromIndex(
              pageIndex,
            );

            return SvgImageMushafPage(
              key: PageStorageKey<String>('svg_page_$pageNumber'),
              pageNumber: pageNumber,
              isCurrentPage: pageNumber == widget.selectedPageNumber,
              cachedPage: _repository.getCachedPage(pageNumber),
              loadPageData: _loadPageDataForSvgView,
              readerTheme: widget.readerTheme,
              hideMode: widget.hideMode,
              waqfHighlightEnabled: widget.waqfHighlightEnabled,
              selection: widget.selection,
              activeAudioWord: widget.activeAudioWord,
              onWordTap: widget.onWordTap,
              onToggleControls: widget.onToggleControls,
              onPageLongPress: widget.onPageLongPress,
              onPageDataReady: widget.onPageDataReady,
            );
          },
        ),
      ),
    );
  }
}

String _svgWebpAssetPath(int pageNumber) {
  return 'assets/quran/svg_pages_quran_only_webp/p${pageNumber.toString().padLeft(3, '0')}_quran_only_transparent.webp';
}

Future<void> _loadSvgImageAssetForWarmUp(int pageNumber) async {
  await rootBundle.load(_svgWebpAssetPath(pageNumber));
}
