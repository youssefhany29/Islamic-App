part of '../qpc_connected_mushaf_page.dart';

extension _QuranReaderLayoutMethods on _QpcConnectedMushafPageState {
  Widget _buildPhoneReaderLayout({
    required BuildContext context,
    required QuranReaderTheme theme,
    required QpcAyahKey? audioTargetAyah,
    required bool showAudioBar,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: QpcMushafPageView(
            pageController: _pageController,
            selectedPageNumber: _selectedPageNumber,
            readerTheme: theme,
            hideMode: _hideMode,
            waqfHighlightEnabled: _waqfHighlightEnabled,
            selection: _selection,
            activeAudioWord: _activeAudioWord,
            fontScale: _fontScale,
            connectedMode: _connectedMode,
            anchorAyahKey: _anchorAyahKey,
            onPageChanged: _onPageChanged,
            onPagePreviewChanged: _onPagePreviewChanged,
            onWordTap: _onWordTap,
            onToggleControls: _toggleControls,
            onPageLongPress: _toggleAudioPanel,
            onPageDataReady: _onPageDataReady,
            onConnectedAnchorChanged: _onConnectedAnchorChanged,
          ),
        ),
        Positioned(
          top: 20.h,
          left: 12.w,
          right: 12.w,
          child: QpcTopControlsBar(
            visible: _controlsVisible,
            readerTheme: theme,
            connectedMode: _connectedMode,
            onBack: () => Navigator.of(context).maybePop(),
            onSearch: _isMemorizationReader
                ? _showMemorizationReaderLimitMessage
                : _openSearch,
            onIndex: _isMemorizationReader
                ? _showMemorizationReaderLimitMessage
                : _openIndexPage,
            onSettings: _openReaderSettings,
            onSaveSurah: _saveCurrentSurahBookmark,
            onToggleConnectedMode: () {
              unawaited(_toggleConnectedMode());
            },
          ),
        ),
        Positioned.fill(
          child: _buildPageInfoHeader(theme, isLargeScreen: false),
        ),
        Positioned(
          right: 18.w,
          bottom: showAudioBar ? 142.h : 66.h,
          child: QpcFloatingHideButton(
            visible: _controlsVisible,
            hideMode: _hideMode,
            readerTheme: theme,
            onTap: _toggleHideMode,
          ),
        ),
        if (showAudioBar)
          Positioned(
            left: 18.w,
            right: 18.w,
            bottom: 68.h,
            child: QpcAudioControlBar(
              readerTheme: theme,
              reciterName: _reciterName,
              volume: _volume,
              isLoading: _isAudioLoading,
              isPlaying: _isAudioPlaying,
              ayahKey: audioTargetAyah,
              activeWord: _activeAudioWord,
              onVolumeChanged: _changeVolume,
              onPlay: () {
                unawaited(_playCurrentAudioTarget());
              },
              onPrevious: () {
                unawaited(_playPreviousAyah());
              },
              onNext: () {
                unawaited(_playNextAyah());
              },
              onReplay: () {
                unawaited(_replayCurrentAyah());
              },
              onStop: () {
                unawaited(_stopAudio());
              },
            ),
          ),
        Positioned(
          left: 18.w,
          right: 18.w,
          bottom: 14.h,
          child: _buildBottomReaderBar(theme),
        ),
      ],
    );
  }

  Widget _buildLargeReaderLayout({
    required BuildContext context,
    required QuranReaderTheme theme,
    required QpcAyahKey? audioTargetAyah,
    required bool showAudioBar,
  }) {
    const double railWidth = 136;
    const double outerGap = 10;

    return Stack(
      children: [
        Positioned.fill(
          right: railWidth + outerGap,
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.pageBackground,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.45),
                  width: 1,
                ),
              ),
            ),
            child: QpcMushafPageView(
              pageController: _pageController,
              selectedPageNumber: _selectedPageNumber,
              readerTheme: theme,
              hideMode: _hideMode,
              waqfHighlightEnabled: _waqfHighlightEnabled,
              selection: _selection,
              activeAudioWord: _activeAudioWord,
              fontScale: _fontScale,
              connectedMode: _connectedMode,
              anchorAyahKey: _anchorAyahKey,
              onPageChanged: _onPageChanged,
              onPagePreviewChanged: _onPagePreviewChanged,
              onWordTap: _onWordTap,
              onToggleControls: _toggleControls,
              onPageLongPress: _toggleAudioPanel,
              onPageDataReady: _onPageDataReady,
              onConnectedAnchorChanged: _onConnectedAnchorChanged,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: railWidth + outerGap,
          bottom: 0,
          child: _buildPageInfoHeader(theme, isLargeScreen: true),
        ),
        Positioned(
          top: outerGap,
          right: outerGap,
          bottom: outerGap,
          width: railWidth,
          child: Column(
            children: [
              _ReaderSideToolsPanel(
                readerTheme: theme,
                connectedMode: _connectedMode,
                hideMode: _hideMode,
                onBack: () => Navigator.of(context).maybePop(),
                onSearch: _isMemorizationReader
                    ? _showMemorizationReaderLimitMessage
                    : _openSearch,
                onIndex: _isMemorizationReader
                    ? _showMemorizationReaderLimitMessage
                    : _openIndexPage,
                onSettings: _openReaderSettings,
                onSaveSurah: _saveCurrentSurahBookmark,
                onToggleConnectedMode: () {
                  unawaited(_toggleConnectedMode());
                },
                onToggleHideMode: _toggleHideMode,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: QpcAudioControlBar(
                  vertical: true,
                  readerTheme: theme,
                  reciterName: _reciterName,
                  volume: _volume,
                  isLoading: _isAudioLoading,
                  isPlaying: _isAudioPlaying,
                  ayahKey: audioTargetAyah,
                  activeWord: _activeAudioWord,
                  onVolumeChanged: _changeVolume,
                  onPlay: () {
                    unawaited(_playCurrentAudioTarget());
                  },
                  onPrevious: () {
                    unawaited(_playPreviousAyah());
                  },
                  onNext: () {
                    unawaited(_playNextAyah());
                  },
                  onReplay: () {
                    unawaited(_replayCurrentAyah());
                  },
                  onStop: () {
                    unawaited(_stopAudio());
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: railWidth + outerGap + 16,
          bottom: 10,
          child: _buildBottomReaderBar(theme),
        ),
      ],
    );
  }

  Widget _buildPageInfoHeader(
    QuranReaderTheme theme, {
    required bool isLargeScreen,
  }) {
    if (_connectedMode) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<_QpcBottomBarSnapshot>(
      valueListenable: _bottomBarSnapshotNotifier,
      builder: (context, snapshot, _) {
        return ValueListenableBuilder<SvgMushafPageMetadata?>(
          valueListenable: _pageMetadataNotifier,
          builder: (context, metadata, _) {
            final SvgMushafPageMetadata? pageMetadata =
                metadata != null && metadata.page == snapshot.pageNumber
                ? metadata
                : null;
            final String surahLabel =
                pageMetadata?.surahSummary ?? snapshot.surahName;
            final int surahCount = pageMetadata?.surahs.length ?? 1;
            final int juzNumber = pageMetadata?.juz ?? snapshot.juzNumber;

            return _QpcManualPageInfoHeader(
              readerTheme: theme,
              surahLabel: surahLabel,
              surahCount: surahCount,
              juzNumber: juzNumber,
              pageNumber: snapshot.pageNumber,
              isLargeScreen: isLargeScreen,
            );
          },
        );
      },
    );
  }

  Widget _buildBottomReaderBar(QuranReaderTheme theme) {
    if (!_connectedMode) {
      return ValueListenableBuilder<_QpcBottomBarSnapshot>(
        valueListenable: _bottomBarSnapshotNotifier,
        builder: (context, snapshot, _) {
          return QpcBottomPageSlider(
            visible: _controlsVisible,
            readerTheme: theme,
            selectedPageNumber: snapshot.pageNumber,
            currentSuraName: snapshot.surahName,
            currentAyahNumber: snapshot.ayahNumber,
            currentJuzNumber: snapshot.juzNumber,
            onPreviewPage: _onPagePreviewChanged,
            onInteractionStart: _handleBottomBarInteractionStart,
            onInteractionEnd: _handleBottomBarInteractionEnd,
            onJumpToPage: (page) {
              unawaited(_jumpToPage(page));
            },
          );
        },
      );
    }

    return _ConnectedReadingStatusBar(
      visible: _controlsVisible,
      readerTheme: theme,
      surahName: _currentSuraName,
      ayahNumber:
          (_anchorAyahKey ?? _selection?.ayahKey ?? _playingAyah)?.ayah ?? 1,
      juzNumber: _currentJuzNumber,
    );
  }
}
