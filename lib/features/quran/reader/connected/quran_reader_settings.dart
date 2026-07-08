part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderSettingsMethods on _QpcConnectedMushafPageState {
  Future<void> _jumpToPage(int pageNumber) async {
    final int safePage = pageNumber.clamp(1, 604).toInt();

    await QuranPageMapper.load();
    final QpcAyahKey pageAnchor = _pageStartAyahKey(safePage);

    if (_pageController.hasClients) {
      _pageController.jumpToPage(_mushafPageIndex(safePage));
    }

    setState(() {
      _selectedPageNumber = safePage;
      _lastMushafPageNumber = safePage;
      _anchorAyahKey = pageAnchor;
      _selection = QuranSelection(ayahKey: pageAnchor);
      _activeAudioWord = null;
    });

    _setBottomBarSnapshotForPage(safePage, ayahKey: pageAnchor);
    _scheduleReadingPersistence(
      ayahKey: pageAnchor,
      mushafPageNumber: safePage,
      wordCount: _repository.getCachedPage(safePage)?.allWords.length,
      recordStats: true,
      reason: 'jump to page',
    );

    _warmUpReaderAssets(safePage, reason: 'jump');
    _restartControlsAutoHideTimer();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _restartControlsAutoHideTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() {
        _controlsVisible = true;
      });
    }

    _restartControlsAutoHideTimer();
  }

  void _toggleAudioPanel() {
    setState(() {
      _controlsVisible = true;
      _audioPanelVisible = !_audioPanelVisible;
    });

    _restartControlsAutoHideTimer();
  }

  void _restartControlsAutoHideTimer() {
    _controlsTimer?.cancel();

    if (_bottomBarInteractionActive) {
      return;
    }

    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _bottomBarInteractionActive) {
        return;
      }

      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _handleBottomBarInteractionStart() {
    _controlsTimer?.cancel();

    if (!_controlsVisible || !_bottomBarInteractionActive) {
      setState(() {
        _controlsVisible = true;
        _bottomBarInteractionActive = true;
      });
    }
  }

  void _handleBottomBarInteractionEnd() {
    if (!_bottomBarInteractionActive) {
      _restartControlsAutoHideTimer();
      return;
    }

    setState(() {
      _bottomBarInteractionActive = false;
    });

    _restartControlsAutoHideTimer();
  }

  void _toggleHideMode() {
    setState(() {
      _hideMode = _hideMode.toggleFullHide();
    });

    _showControls();
  }

  void _toggleWaqfHighlight() {
    setState(() {
      _waqfHighlightEnabled = !_waqfHighlightEnabled;
    });

    _showControls();
  }

  void _increaseFont() {
    setState(() {
      _fontScale = (_fontScale + 0.03).clamp(0.92, 1.08).toDouble();
    });

    _showControls();
  }

  void _decreaseFont() {
    setState(() {
      _fontScale = (_fontScale - 0.03).clamp(0.92, 1.08).toDouble();
    });

    _showControls();
  }

  Future<void> _toggleConnectedMode() async {
    await QuranPageMapper.load();

    final bool switchingToMushaf = _connectedMode;

    // _anchorAyahKey is the live ayah coming from the connected text reader.
    // Do not prefer _selection here, because _selection can be an old tap
    // selection from the mushaf page and it breaks text -> mushaf syncing.
    final QpcAyahKey anchor =
        _anchorAyahKey ??
        _selection?.ayahKey ??
        _pageStartAyahKey(_selectedPageNumber);
    final int pageNumber = _pageNumberForAyah(anchor);

    setState(() {
      _connectedMode = !_connectedMode;
      _previewAyahKey = null;
      _anchorAyahKey = anchor;
      _selectedPageNumber = pageNumber;
      _selection = QuranSelection(ayahKey: anchor);
      _controlsVisible = true;

      if (switchingToMushaf) {
        _lastMushafPageNumber = pageNumber;
      }
    });

    if (switchingToMushaf) {
      _jumpMushafControllerToPage(pageNumber);
      _setBottomBarSnapshotForPage(pageNumber, ayahKey: anchor);
      _warmUpReaderAssets(pageNumber, reason: 'switch to mushaf');
    }

    _showControls();
    _showInfoSnackBar(_connectedMode ? 'وضع نصي متصل' : 'وضع مصحف');
  }

  void _jumpMushafControllerToPage(int pageNumber) {
    final int safePage = pageNumber.clamp(1, 604).toInt();

    void jumpNow() {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final int targetIndex = _mushafPageIndex(safePage);
      final int currentIndex =
          (_pageController.page ?? _pageController.initialPage.toDouble())
              .round();

      if (currentIndex != targetIndex) {
        _pageController.jumpToPage(targetIndex);
      }
    }

    jumpNow();

    // When switching from connected text mode, the PageView is mounted only
    // after setState finishes. This post-frame jump is what keeps the visual
    // mushaf page synced with the bottom bar and the current ayah.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      jumpNow();
    });
  }

  Future<void> _openIndexPage() async {
    _showControls();

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const IndexPage();
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _openReaderSettings() async {
    _showControls();

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _themeController.theme.pageBackground,
      barrierColor: Colors.black.withOpacity(0.28),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AnimatedBuilder(
              animation: _themeController,
              builder: (context, _) {
                final QuranReaderTheme activeTheme = _themeController.theme;
                final bool isLargeSheet =
                    MediaQuery.sizeOf(context).width >= 600;
                final double sheetHeightFactor = isLargeSheet ? 0.58 : 0.72;
                final EdgeInsetsGeometry sheetPadding = isLargeSheet
                    ? const EdgeInsets.fromLTRB(16, 4, 16, 14)
                    : EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 18.h);

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: FractionallySizedBox(
                    heightFactor: sheetHeightFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeTheme.pageBackground,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22.r),
                        ),
                      ),
                      child: Padding(
                        padding: sheetPadding,
                        child: ListView(
                          children: [
                            Text(
                              'إعدادات القراءة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: isLargeSheet ? 13 : 15.sp,
                                fontWeight: FontWeight.w900,
                                color: activeTheme.textColor,
                              ),
                            ),
                            SizedBox(height: isLargeSheet ? 9 : 14.h),
                            _SettingsTitle(
                              title: 'وضع القراءة',
                              readerTheme: activeTheme,
                            ),
                            SizedBox(height: isLargeSheet ? 6 : 8.h),
                            _SettingsTile(
                              icon: Icons.compare_arrows_rounded,
                              title: _connectedMode
                                  ? 'وضع نصي متصل'
                                  : 'وضع المصحف',
                              subtitle: '',
                              readerTheme: activeTheme,
                              onTap: () {
                                unawaited(_toggleConnectedMode());
                              },
                            ),
                            if (_connectedMode) ...[
                              SizedBox(height: isLargeSheet ? 9 : 14.h),
                              _SettingsTitle(
                                title: 'حجم الخط (وضع متصل)',
                                readerTheme: activeTheme,
                              ),
                              SizedBox(height: isLargeSheet ? 6 : 8.h),
                              _FontScaleSlider(
                                readerTheme: activeTheme,
                                value: _fontScale,
                                onChanged: (value) {
                                  setState(() {
                                    _fontScale = value
                                        .clamp(0.92, 1.18)
                                        .toDouble();
                                  });
                                  setSheetState(() {});
                                  _showControls();
                                },
                              ),
                            ],
                            if (!_connectedMode) ...[
                              SizedBox(height: isLargeSheet ? 9 : 14.h),
                              _SettingsTitle(
                                title: 'تمييز الوقف',
                                readerTheme: activeTheme,
                              ),
                              SizedBox(height: isLargeSheet ? 6 : 8.h),
                              _SettingsTile(
                                icon: _waqfHighlightEnabled
                                    ? Icons.check_circle_rounded
                                    : Icons.pause_circle_outline_rounded,
                                title: _waqfHighlightEnabled
                                    ? 'تمييز علامات الوقف مفعل'
                                    : 'تمييز علامات الوقف',
                                subtitle: '',
                                readerTheme: activeTheme,
                                onTap: () {
                                  _toggleWaqfHighlight();
                                  setSheetState(() {});
                                },
                              ),
                            ],
                            SizedBox(height: isLargeSheet ? 9 : 14.h),
                            _SettingsTitle(
                              title: 'القارئ',
                              readerTheme: activeTheme,
                            ),
                            SizedBox(height: isLargeSheet ? 6 : 8.h),
                            ...QuranAyahAudioService.reciters.map((reciter) {
                              final bool selected =
                                  reciter.id == _audioService.currentReciter.id;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLargeSheet ? 6 : 8.h,
                                ),
                                child: _SettingsTile(
                                  icon: selected
                                      ? Icons.check_circle_rounded
                                      : Icons.record_voice_over_rounded,
                                  title: reciter.name,
                                  subtitle: selected ? 'القارئ الحالي' : '',
                                  readerTheme: activeTheme,
                                  onTap: () async {
                                    await _selectReciter(reciter);

                                    if (context.mounted) {
                                      setSheetState(() {});
                                    }
                                  },
                                ),
                              );
                            }),
                            SizedBox(height: isLargeSheet ? 9 : 14.h),
                            _SettingsTitle(
                              title: 'ألوان القراءة',
                              readerTheme: activeTheme,
                            ),
                            SizedBox(height: isLargeSheet ? 6 : 8.h),
                            ...QuranReaderTheme.all.map((readerTheme) {
                              final bool selected =
                                  readerTheme.id == activeTheme.id;

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLargeSheet ? 6 : 8.h,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    isLargeSheet ? 13 : 16.r,
                                  ),
                                  onTap: () {
                                    unawaited(
                                      _themeController.setTheme(readerTheme.id),
                                    );
                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    padding: isLargeSheet
                                        ? const EdgeInsets.all(9)
                                        : EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: readerTheme.pageBackground,
                                      borderRadius: BorderRadius.circular(
                                        isLargeSheet ? 13 : 16.r,
                                      ),
                                      border: Border.all(
                                        color: selected
                                            ? readerTheme.selectedWordTextColor
                                            : readerTheme.pageBadgeBorder
                                                  .withOpacity(0.45),
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: isLargeSheet ? 22 : 28.w,
                                          height: isLargeSheet ? 22 : 28.w,
                                          decoration: BoxDecoration(
                                            color: readerTheme.pageBackground,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  readerTheme.pageBadgeBorder,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: isLargeSheet ? 8 : 10.w,
                                        ),
                                        Expanded(
                                          child: Text(
                                            readerTheme.label,
                                            style: TextStyle(
                                              fontFamily: 'cairo',
                                              fontSize: isLargeSheet
                                                  ? 10
                                                  : 13.sp,
                                              fontWeight: FontWeight.w900,
                                              color: readerTheme.textColor,
                                            ),
                                          ),
                                        ),
                                        if (selected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: readerTheme
                                                .selectedWordTextColor,
                                            size: isLargeSheet ? 17 : 20.sp,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
