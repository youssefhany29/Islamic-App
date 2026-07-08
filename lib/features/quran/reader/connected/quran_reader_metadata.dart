part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderMetadataMethods on _QpcConnectedMushafPageState {
  QpcAyahKey? _initialAnchorAyahKey() {
    final int? explicitIndex = widget.initialGlobalAyahIndex;
    final int? wirdStart = widget.wirdStartGlobalAyahIndex;
    final int? memorizationStart = widget.memorizationStartGlobalAyahIndex;

    final int? targetGlobalIndex =
        explicitIndex ?? memorizationStart ?? wirdStart;
    if (targetGlobalIndex == null) {
      return null;
    }

    final int safeIndex = targetGlobalIndex
        .clamp(0, QuranReaderHelpers.totalAyahs - 1)
        .toInt();
    final QuranAyahPosition position =
        QuranReaderHelpers.getPositionFromGlobalIndex(safeIndex);

    return QpcAyahKey(
      surah: position.suraIndex + 1,
      ayah: position.ayahIndex + 1,
    );
  }

  Future<void> _syncInitialPageFromAnchor() async {
    final QpcAyahKey? anchor = _anchorAyahKey;
    if (anchor == null) {
      return;
    }

    await QuranPageMapper.load();
    if (!mounted) {
      return;
    }

    final int pageNumber = _pageNumberForAyah(anchor);
    if (pageNumber == _selectedPageNumber) {
      return;
    }

    _pageController.jumpToPage(_mushafPageIndex(pageNumber));
    setState(() {
      _selectedPageNumber = pageNumber;
      _lastMushafPageNumber = pageNumber;
    });
    _setBottomBarSnapshotForPage(pageNumber, ayahKey: anchor);
    _warmUpReaderAssets(pageNumber, reason: 'initial anchor sync');
  }

  int _pageNumberForAyah(QpcAyahKey ayahKey) {
    final int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: (ayahKey.surah - 1).clamp(0, 113).toInt(),
      ayahIndex: (ayahKey.ayah - 1).clamp(0, 286).toInt(),
    );

    return QuranPageMapper.getPageNumberForGlobalAyah(
      globalAyahIndex,
    ).clamp(1, 604).toInt();
  }

  QpcAyahKey _pageStartAyahKey(int pageNumber) {
    final int globalAyahIndex = QuranPageMapper.getGlobalAyahIndexForPage(
      pageNumber.clamp(1, 604).toInt(),
    );
    final QuranAyahPosition position =
        QuranReaderHelpers.getPositionFromGlobalIndex(globalAyahIndex);

    return QpcAyahKey(
      surah: position.suraIndex + 1,
      ayah: position.ayahIndex + 1,
    );
  }

  void _setBottomBarSnapshotForPage(int pageNumber, {QpcAyahKey? ayahKey}) {
    unawaited(_syncPageMetadata(pageNumber));

    final _QpcBottomBarSnapshot nextSnapshot = _bottomBarSnapshotForPage(
      pageNumber,
      ayahKey: ayahKey,
    );

    if (_bottomBarSnapshotNotifier.value == nextSnapshot) {
      return;
    }

    _bottomBarSnapshotNotifier.value = nextSnapshot;
  }

  Future<void> _syncPageMetadata(int pageNumber) async {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    if (_pageMetadataNotifier.value?.page == safePage) {
      return;
    }

    final int token = ++_pageMetadataRequestToken;
    try {
      final SvgMushafPageMetadata? metadata =
          await SvgMushafPageMetadataRepository.instance.loadPage(safePage);
      if (!mounted || token != _pageMetadataRequestToken) {
        return;
      }
      _pageMetadataNotifier.value = metadata;
    } catch (_) {
      if (!mounted || token != _pageMetadataRequestToken) {
        return;
      }
      _pageMetadataNotifier.value = null;
    }
  }

  void _scheduleBottomBarPreview(int pageNumber) {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    if (_bottomBarSnapshotNotifier.value.pageNumber == safePage) {
      return;
    }

    _pendingBottomPreviewPage = safePage;

    final DateTime now = DateTime.now();
    final DateTime? lastUpdate = _lastBottomPreviewUpdateAt;
    const Duration throttle = Duration(milliseconds: 48);

    if (lastUpdate == null || now.difference(lastUpdate) >= throttle) {
      _applyPendingBottomBarPreview();
      return;
    }

    _previewUpdateTimer?.cancel();
    _previewUpdateTimer = Timer(throttle - now.difference(lastUpdate), () {
      _applyPendingBottomBarPreview();
    });
  }

  void _applyPendingBottomBarPreview() {
    final int? pendingPage = _pendingBottomPreviewPage;
    if (!mounted || pendingPage == null) {
      return;
    }

    _pendingBottomPreviewPage = null;
    _lastBottomPreviewUpdateAt = DateTime.now();
    _setBottomBarSnapshotForPage(pendingPage);
  }

  int _globalIndexForAyah(QpcAyahKey ayahKey) {
    return QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: (ayahKey.surah - 1).clamp(0, 113).toInt(),
      ayahIndex: (ayahKey.ayah - 1).clamp(0, 286).toInt(),
    );
  }

  QpcAyahKey _ayahKeyFromGlobalIndex(int globalAyahIndex) {
    final int safeIndex = globalAyahIndex
        .clamp(0, QuranReaderHelpers.totalAyahs - 1)
        .toInt();
    final QuranAyahPosition position =
        QuranReaderHelpers.getPositionFromGlobalIndex(safeIndex);

    return QpcAyahKey(
      surah: position.suraIndex + 1,
      ayah: position.ayahIndex + 1,
    );
  }

  QpcAyahKey _pageEndAyahKey(int pageNumber) {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    final int nextPage = safePage + 1;
    final int endGlobalAyahIndex;

    if (nextPage <= 604) {
      endGlobalAyahIndex =
          QuranPageMapper.getGlobalAyahIndexForPage(nextPage) - 1;
    } else {
      endGlobalAyahIndex = QuranReaderHelpers.totalAyahs - 1;
    }

    return _ayahKeyFromGlobalIndex(endGlobalAyahIndex);
  }

  bool get _isWirdReader {
    final String? planId = widget.wirdPlanId;
    return planId != null && planId.trim().isNotEmpty;
  }

  bool get _isMemorizationReader {
    final String? taskId = widget.memorizationTaskId;
    return taskId != null && taskId.trim().isNotEmpty;
  }

  QpcAyahKey _mushafProgressAyahKeyForPage(int pageNumber) {
    // في المصحف لا نعرف الآية الدقيقة داخل الصفحة، لذلك للورد نحسب نهاية الصفحة.
    // وعند قلب الصفحة نحفظ الصفحة السابقة كنقطة تقدم، وبكده آخر آية لا تضيع.
    if (_isWirdReader || _isMemorizationReader) {
      return _pageEndAyahKey(pageNumber);
    }

    final QpcAyahKey? currentAnchor = _anchorAyahKey;
    if (currentAnchor != null && _isAnchorOnPage(currentAnchor, pageNumber)) {
      return currentAnchor;
    }

    return _pageStartAyahKey(pageNumber);
  }

  bool _isAnchorOnPage(QpcAyahKey ayahKey, int pageNumber) {
    return _pageNumberForAyah(ayahKey) == pageNumber.clamp(1, 604);
  }

  String get _currentSuraName {
    final QpcAyahKey? displayKey = _connectedMode
        ? (_anchorAyahKey ?? _selection?.ayahKey ?? _playingAyah)
        : (_selection?.ayahKey ??
              _previewAyahKey ??
              _anchorAyahKey ??
              _playingAyah);

    final int? surah = displayKey?.surah;

    if (surah != null && surah >= 1 && surah <= 114) {
      return QuranReaderHelpers.getSuraName(surah - 1);
    }

    final QpcPageData? pageData = _visiblePageData;
    if (pageData != null && pageData.allWords.isNotEmpty) {
      final int pageSurah = pageData.allWords.first.surah;
      if (pageSurah >= 1 && pageSurah <= 114) {
        return QuranReaderHelpers.getSuraName(pageSurah - 1);
      }
    }

    return 'الفاتحة';
  }

  int get _currentJuzNumber {
    final QpcAyahKey? ayahKey = _connectedMode
        ? (_anchorAyahKey ?? _selection?.ayahKey ?? _playingAyah)
        : (_selection?.ayahKey ??
              _previewAyahKey ??
              _anchorAyahKey ??
              _playingAyah);

    if (ayahKey != null) {
      return QuranReaderHelpers.getJuzNumber(
        suraIndex: (ayahKey.surah - 1).clamp(0, 113).toInt(),
        ayahIndex: (ayahKey.ayah - 1).clamp(0, 286).toInt(),
      );
    }

    int result = 1;

    for (int index = 0; index < _juzStartPages.length; index++) {
      if (_selectedPageNumber >= _juzStartPages[index]) {
        result = index + 1;
      } else {
        break;
      }
    }

    return result;
  }
}
