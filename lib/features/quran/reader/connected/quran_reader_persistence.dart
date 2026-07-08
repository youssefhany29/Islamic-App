part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderPersistenceMethods on _QpcConnectedMushafPageState {
  void _onPageChanged(int pageNumber) {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    final int? memorizationStart = widget.memorizationStartGlobalAyahIndex;
    final int? memorizationEnd = widget.memorizationEndGlobalAyahIndex;
    if (_isMemorizationReader &&
        memorizationStart != null &&
        memorizationEnd != null) {
      final int firstTaskPage = QuranPageMapper.getPageNumberForGlobalAyah(
        memorizationStart,
      );
      final int lastTaskPage = QuranPageMapper.getPageNumberForGlobalAyah(
        memorizationEnd,
      );
      if (safePage < firstTaskPage || safePage > lastTaskPage) {
        final int boundaryPage = safePage < firstTaskPage
            ? firstTaskPage
            : lastTaskPage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_mushafPageIndex(boundaryPage));
          }
          _showMemorizationReaderLimitMessage(
            completedTodayRange: safePage > lastTaskPage,
          );
        });
        return;
      }
    }
    final int? previousMushafPage = _lastMushafPageNumber;

    QpcAyahKey? ayahToSave;
    int pageToSave = safePage;

    setState(() {
      _selectedPageNumber = safePage;
      _previewAyahKey = null;

      if (!_connectedMode) {
        // عند عرض المصحف: الآية النشطة للواجهة تكون أول آية في الصفحة الحالية،
        // لكن تقدم الورد يُحسب من نهاية الصفحة السابقة بعد قلبها.
        final QpcAyahKey pageAnchor = _pageStartAyahKey(safePage);
        _anchorAyahKey = pageAnchor;

        if (previousMushafPage != null && previousMushafPage != safePage) {
          pageToSave = previousMushafPage;
          ayahToSave = _mushafProgressAyahKeyForPage(previousMushafPage);
        } else if (safePage == 604) {
          pageToSave = safePage;
          ayahToSave = _mushafProgressAyahKeyForPage(safePage);
        }

        _lastMushafPageNumber = safePage;
        _selection = null;
        _activeAudioWord = null;
      }
    });

    if (!_connectedMode && ayahToSave != null) {
      _scheduleReadingPersistence(
        ayahKey: ayahToSave!,
        mushafPageNumber: pageToSave,
        wordCount: _repository.getCachedPage(pageToSave)?.allWords.length,
        recordStats: true,
        reason: 'mushaf previous page settled',
      );
    }

    _setBottomBarSnapshotForPage(
      safePage,
      ayahKey: !_connectedMode ? _anchorAyahKey : null,
    );
    _restartControlsAutoHideTimer();
  }

  void _showMemorizationReaderLimitMessage({bool completedTodayRange = false}) {
    if (!mounted) return;

    if (completedTodayRange) {
      if (_shownMemorizationCompletionMessage) return;
      _shownMemorizationCompletionMessage = true;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showMemorizationCompletionSheet();
      return;
    }

    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.secondary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.10)),
        ),
        content: Text(
          'مهمة الخطة تعرض صفحات الحفظ المطلوبة اليوم فقط.',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: 3,
          softWrap: true,
          style: TextStyle(
            color: theme.colorScheme.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showMemorizationCompletionSheet() {
    final rootContext = context;
    showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final successColor = Colors.green.shade600;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: colors.outline.withOpacity(0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 18,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: successColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: successColor,
                            size: 25.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'أنهيت ورد الحفظ المطلوب اليوم',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.surface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17.sp,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'لو حابب تكمل، افتح من صفحة القرآن أو عدّل الخطة.',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.surface.withOpacity(0.68),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(
                                color: colors.primary.withOpacity(0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              textStyle: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('حسناً'),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              if (Navigator.of(rootContext).canPop()) {
                                Navigator.of(rootContext).pop(true);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              textStyle: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            icon: Icon(Icons.menu_book_rounded, size: 17.sp),
                            label: const Text('فتح القرآن'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPagePreviewChanged(int pageNumber) {
    if (!mounted || _connectedMode) {
      return;
    }

    final int safePage = pageNumber.clamp(1, 604).toInt();
    _scheduleBottomBarPreview(safePage);
  }

  void _onConnectedAnchorChanged(QpcAyahKey ayahKey, int pageNumber) {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    final bool pageChanged = safePage != _selectedPageNumber;

    setState(() {
      _anchorAyahKey = ayahKey;
      _previewAyahKey = null;
      _selectedPageNumber = safePage;
    });
    _setBottomBarSnapshotForPage(safePage, ayahKey: ayahKey);

    _scheduleReadingPersistence(
      ayahKey: ayahKey,
      mushafPageNumber: safePage,
      recordStats: pageChanged,
      reason: 'connected anchor settled',
    );
  }

  void _onPageDataReady(QpcPageData pageData) {
    if (!mounted || pageData.pageNumber != _selectedPageNumber) {
      return;
    }

    if (_visiblePageData?.pageNumber != pageData.pageNumber) {
      setState(() {
        _visiblePageData = pageData;
      });
    }
    _setBottomBarSnapshotForPage(
      pageData.pageNumber,
      ayahKey: _selection?.ayahKey ?? _anchorAyahKey,
    );

    // في المصحف داخل الورد، الحفظ يتم عند قلب الصفحة السابقة حتى لا نحسب أول آية فقط.
    if (!(!_connectedMode && _isWirdReader)) {
      _scheduleReadingPersistenceFromPage(pageData, reason: 'page data ready');
    }
  }

  void _scheduleReadingPersistenceFromPage(
    QpcPageData pageData, {
    required String reason,
  }) {
    QpcAyahKey? targetAyah = _anchorAyahKey;

    if (!_connectedMode && _isMemorizationReader) {
      targetAyah = _mushafProgressAyahKeyForPage(pageData.pageNumber);
    }

    if (targetAyah == null || !pageData.containsAyah(targetAyah)) {
      final QpcWord? firstWord = pageData.allWords.isNotEmpty
          ? pageData.allWords.first
          : null;
      if (firstWord == null) {
        return;
      }
      targetAyah = firstWord.ayahKey;
    }

    _scheduleReadingPersistence(
      ayahKey: targetAyah,
      mushafPageNumber: pageData.pageNumber,
      wordCount: pageData.allWords.length,
      recordStats: true,
      reason: reason,
    );
  }

  void _scheduleReadingPersistence({
    required QpcAyahKey ayahKey,
    required int mushafPageNumber,
    int? wordCount,
    bool recordStats = true,
    required String reason,
  }) {
    _pendingReadingPersistence = _QpcPendingReadingPersistence(
      ayahKey: ayahKey,
      mushafPageNumber: mushafPageNumber.clamp(1, 604).toInt(),
      wordCount: wordCount,
      recordStats: recordStats,
      reason: reason,
    );

    _readingPersistenceTimer?.cancel();
    _readingPersistenceTimer = Timer(const Duration(milliseconds: 280), () {
      final _QpcPendingReadingPersistence? pending = _pendingReadingPersistence;
      if (!mounted || pending == null) {
        return;
      }

      _pendingReadingPersistence = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        unawaited(_flushReadingPersistence(pending));
      });
    });
  }

  Future<void> _flushReadingPersistence(
    _QpcPendingReadingPersistence pending,
  ) async {
    await QpcReaderPerf.timeAsync(
      'persist ${pending.reason} p${pending.mushafPageNumber}',
      () async {
        await _saveReadingPosition(
          ayahKey: pending.ayahKey,
          mushafPageNumber: pending.mushafPageNumber,
        );

        if (pending.recordStats) {
          await QuranReadingStatsStorage.recordReadPage(
            pending.mushafPageNumber,
            wordCount: pending.wordCount,
          );
        }
      },
    );
  }

  Future<void> _saveReadingPosition({
    required QpcAyahKey ayahKey,
    required int mushafPageNumber,
  }) async {
    int suraIndex = (ayahKey.surah - 1).clamp(0, 113).toInt();
    int ayahIndex = (ayahKey.ayah - 1).clamp(0, 286).toInt();
    int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: suraIndex,
      ayahIndex: ayahIndex,
    );

    final int? wirdStart = widget.wirdStartGlobalAyahIndex;
    final int? wirdEnd = widget.wirdEndGlobalAyahIndex;
    final int? memorizationStart = widget.memorizationStartGlobalAyahIndex;
    final int? memorizationEnd = widget.memorizationEndGlobalAyahIndex;

    if (wirdStart != null && wirdEnd != null && wirdStart <= wirdEnd) {
      globalAyahIndex = globalAyahIndex.clamp(wirdStart, wirdEnd).toInt();

      final QuranAyahPosition position =
          QuranReaderHelpers.getPositionFromGlobalIndex(globalAyahIndex);
      suraIndex = position.suraIndex;
      ayahIndex = position.ayahIndex;
    }

    if (memorizationStart != null &&
        memorizationEnd != null &&
        memorizationStart <= memorizationEnd) {
      globalAyahIndex = globalAyahIndex
          .clamp(memorizationStart, memorizationEnd)
          .toInt();

      final QuranAyahPosition position =
          QuranReaderHelpers.getPositionFromGlobalIndex(globalAyahIndex);
      suraIndex = position.suraIndex;
      ayahIndex = position.ayahIndex;
    }

    if (widget.saveAsLastRead) {
      await QuranReaderStorage.saveLastRead(
        suraIndex: suraIndex,
        ayahIndex: ayahIndex,
        viewMode: 'qpc_connected',
        mushafPageNumber: mushafPageNumber,
      );
    }

    if (widget.saveAsMushafOpenProgress) {
      await QuranReaderStorage.saveMushafOpenProgress(
        suraIndex: suraIndex,
        ayahIndex: ayahIndex,
        viewMode: 'qpc_connected',
        mushafPageNumber: mushafPageNumber,
      );
    }

    final String? wirdPlanId = widget.wirdPlanId;
    if (wirdPlanId != null && wirdPlanId.trim().isNotEmpty) {
      await QuranWirdProgressStorage.saveProgress(
        planId: wirdPlanId,
        suraIndex: suraIndex,
        ayahIndex: ayahIndex,
        mushafPageNumber: mushafPageNumber,
        viewMode: 'qpc_connected',
      );

      await _tryAutoCompleteWird(globalAyahIndex: globalAyahIndex);
    }

    final String? memorizationTaskId = widget.memorizationTaskId;
    if (memorizationTaskId != null && memorizationTaskId.trim().isNotEmpty) {
      final int safePage = mushafPageNumber.clamp(1, 604).toInt();
      final int pageStart = QuranPageMapper.getGlobalAyahIndexForPage(safePage);
      final int pageEnd = safePage == 604
          ? QuranReaderHelpers.totalAyahs - 1
          : QuranPageMapper.getGlobalAyahIndexForPage(safePage + 1) - 1;
      final int requiredPageStart = memorizationStart == null
          ? pageStart
          : math.max(pageStart, memorizationStart);
      final int requiredPageEnd = memorizationEnd == null
          ? pageEnd
          : math.min(pageEnd, memorizationEnd);

      await QuranMemorizationProgressStorage.saveProgress(
        taskId: memorizationTaskId,
        suraIndex: suraIndex,
        ayahIndex: ayahIndex,
        globalAyahIndex: globalAyahIndex,
        mushafPageNumber: mushafPageNumber,
        pageStartGlobalAyahIndex: requiredPageStart,
        pageEndGlobalAyahIndex: requiredPageEnd,
        viewMode: 'qpc_connected',
        step: widget.memorizationStep.trim().isEmpty
            ? 'reading'
            : widget.memorizationStep,
      );
    }
  }

  Future<void> _tryAutoCompleteWird({required int globalAyahIndex}) async {
    final String? planId = widget.wirdPlanId;
    final int? endGlobalAyahIndex = widget.wirdEndGlobalAyahIndex;

    if (planId == null || planId.trim().isEmpty) {
      return;
    }
    if (endGlobalAyahIndex == null) {
      return;
    }
    if (_didAutoCompleteWird) {
      return;
    }
    if (globalAyahIndex < endGlobalAyahIndex) {
      return;
    }

    _didAutoCompleteWird = true;

    final List<QuranKhatmaPlan> activePlansBefore =
        await QuranWirdStorage.getActivePlans();
    final int planIndex = activePlansBefore.indexWhere(
      (plan) => plan.id == planId,
    );

    if (planIndex == -1) {
      return;
    }

    final QuranKhatmaPlan currentPlan = activePlansBefore[planIndex];
    final bool willCompleteKhatma =
        currentPlan.completedDays + 1 >= currentPlan.totalDays;

    final int startGlobalAyahIndex =
        widget.wirdStartGlobalAyahIndex ?? endGlobalAyahIndex;
    final int fromPage = QuranPageMapper.getPageNumberForGlobalAyah(
      startGlobalAyahIndex,
    );
    final int toPage = QuranPageMapper.getPageNumberForGlobalAyah(
      endGlobalAyahIndex,
    );
    final int completedPages = (toPage - fromPage + 1).clamp(1, 604).toInt();

    await QuranWirdStorage.markPlanTodayWirdCompleted(planId);
    await QuranWirdProgressStorage.clearProgress(planId);
    await QuranReadingStatsStorage.recordCompletedWird(
      completedPages: completedPages,
      completedKhatma: willCompleteKhatma,
    );

    if (!mounted) {
      return;
    }

    await _stopAudio();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final QuranReaderTheme theme = _themeController.theme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.controlsBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              willCompleteKhatma
                  ? 'ما شاء الله! اكتملت الختمة'
                  : 'ما شاء الله! أنهيت ورد اليوم',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: theme.controlsTextColor,
              ),
            ),
            content: Text(
              'ارجع لصفحة الورد لتبدأ وردًا جديدًا، أو افتح المصحف العادي لو عايز تكمل قراءة بدون ما يتلخبط حساب الورد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 12.sp,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: theme.controlsTextColor.withOpacity(0.82),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'العودة',
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: theme.selectedWordTextColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).maybePop(true);
  }

  Future<void> _saveCurrentSurahBookmark() async {
    final QpcAyahKey anchor =
        _anchorAyahKey ?? _pageStartAyahKey(_selectedPageNumber);

    final int surah = anchor.surah;
    final int ayah = anchor.ayah;

    await QuranBookmarkStorage.addBookmark(
      QuranBookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        suraIndex: surah - 1,
        ayahIndex: ayah - 1,
        mushafPageNumber: _selectedPageNumber,
        viewMode: 'qpc_connected',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    if (!mounted) {
      return;
    }

    _showControls();
    _showInfoSnackBar('تم حفظ الموضع');
  }
}
