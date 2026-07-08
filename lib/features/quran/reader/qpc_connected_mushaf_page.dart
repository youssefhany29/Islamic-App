import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../audio/quran_ayah_audio_service.dart';
import '../main_quraan_components/constant.dart';
import '../main_quraan_components/index.dart';
import 'audio/quran_word_sync_controller.dart';
import 'data/qpc_mushaf_repository.dart';
import 'data/qpc_reader_perf.dart';
import 'hiding/quran_hide_mode.dart';
import 'irab/quran_irab_sheet.dart';
import 'models/qpc_models.dart';
import 'models/quran_ayah_sheet_text.dart';
import 'models/quran_ayah_tap_result.dart';
import 'models/quran_selection.dart';
import 'quran_bookmark_storage.dart';
import 'quran_page_mapper.dart';
import 'qpc_ayah_search_page.dart';
import 'quran_reader_helpers.dart';
import 'quran_reader_storage.dart';
import 'svg/svg_mushaf_geometry_repository.dart';
import 'svg/svg_mushaf_page_metadata.dart';
import '../memorization/services/quran_memorization_progress_storage.dart';
import '../wird/quran_wird_progress_storage.dart';
import '../wird/quran_wird_storage.dart';
import '../stats/quran_reading_stats_storage.dart';
import 'tafsir/quran_tafsir_sheet.dart';
import 'theme/quran_reader_theme.dart';
import 'theme/quran_reader_theme_controller.dart';
import 'widgets/qpc_audio_control_bar.dart';
import 'widgets/qpc_bottom_page_slider.dart';
import 'widgets/qpc_floating_hide_button.dart';
import 'widgets/qpc_mushaf_page_view.dart';
import 'widgets/qpc_top_controls_bar.dart';
part 'connected/quran_reader_support.dart';
part 'connected/quran_reader_support_models.dart';
part 'connected/quran_reader_support_panels.dart';
part 'connected/quran_reader_support_selection.dart';
part 'connected/quran_reader_support_settings.dart';
part 'connected/quran_reader_audio.dart';
part 'connected/quran_reader_layout.dart';
part 'connected/quran_reader_settings.dart';
part 'connected/quran_reader_selection.dart';
part 'connected/quran_reader_persistence.dart';
part 'connected/quran_reader_metadata.dart';
part 'connected/quran_reader_search.dart';
part 'connected/quran_reader_warmup.dart';
part 'connected/quran_reader_helpers.dart';

enum _QuranSelectionAction { play, tafsir, irab, clear }

class QpcConnectedMushafPage extends StatefulWidget {
  const QpcConnectedMushafPage({
    super.key,
    this.initialPage = 1,
    this.initialGlobalAyahIndex,
    this.initialHideMode = QuranHideMode.visible,
    this.openedFromTest = false,
    this.saveAsLastRead = true,
    this.saveAsMushafOpenProgress = false,
    this.wirdPlanId,
    this.wirdStartGlobalAyahIndex,
    this.wirdEndGlobalAyahIndex,
    this.memorizationTaskId,
    this.memorizationStartGlobalAyahIndex,
    this.memorizationEndGlobalAyahIndex,
    this.memorizationStep = 'reading',
  });

  final int initialPage;
  final int? initialGlobalAyahIndex;
  final QuranHideMode initialHideMode;
  final bool openedFromTest;
  final bool saveAsLastRead;
  final bool saveAsMushafOpenProgress;
  final String? wirdPlanId;
  final int? wirdStartGlobalAyahIndex;
  final int? wirdEndGlobalAyahIndex;
  final String? memorizationTaskId;
  final int? memorizationStartGlobalAyahIndex;
  final int? memorizationEndGlobalAyahIndex;
  final String memorizationStep;

  @override
  State<QpcConnectedMushafPage> createState() => _QpcConnectedMushafPageState();
}

class _QpcConnectedMushafPageState extends State<QpcConnectedMushafPage> {
  late final PageController _pageController;

  final QpcMushafRepository _repository = QpcMushafRepository.instance;
  final QuranAyahAudioService _audioService = QuranAyahAudioService.instance;
  final QuranWordSyncController _wordSyncController =
      const QuranWordSyncController();
  final QuranReaderThemeController _themeController =
      QuranReaderThemeController.instance;
  final SvgMushafGeometryRepository _svgGeometryRepository =
      SvgMushafGeometryRepository.instance;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _controlsTimer;
  Timer? _autoNextTimer;
  Timer? _previewUpdateTimer;
  Timer? _readingPersistenceTimer;

  int _selectedPageNumber = 1;
  QpcAyahKey? _anchorAyahKey;
  int? _lastMushafPageNumber;
  bool _didAutoCompleteWird = false;
  bool _shownMemorizationCompletionMessage = false;

  bool _controlsVisible = true;
  bool _bottomBarInteractionActive = false;
  bool _audioPanelVisible = false;
  bool _connectedMode = false;
  bool _waqfHighlightEnabled = false;

  // Used only for the bottom slider live preview while dragging/scrolling.
  // Do NOT use this as the mode-switch anchor, otherwise switching between
  // connected text and mushaf loses the exact selected/active ayah.
  QpcAyahKey? _previewAyahKey;

  bool _isAudioLoading = false;
  bool _isAudioPlaying = false;
  bool _autoContinueSurah = false;
  bool _userStoppedAudio = false;

  double _fontScale = 1.0;
  double _volume = 1.0;

  String _reciterName = QuranAyahAudioService.instance.currentReciter.name;

  QuranHideMode _hideMode = QuranHideMode.visible;
  QuranSelection? _selection;
  QpcPageData? _visiblePageData;

  QpcAyahKey? _playingAyah;
  QpcWordKey? _activeAudioWord;
  QuranAyahAudioInfo? _currentAudioInfo;
  List<QpcWord> _currentPlayingAyahWords = <QpcWord>[];
  int _audioRequestToken = 0;
  bool _isAutoAdvancingAudio = false;
  QpcAyahKey? _lastCompletedAudioAyah;
  _QpcPendingReadingPersistence? _pendingReadingPersistence;
  late final ValueNotifier<_QpcBottomBarSnapshot> _bottomBarSnapshotNotifier;
  late final ValueNotifier<SvgMushafPageMetadata?> _pageMetadataNotifier;
  int _pageMetadataRequestToken = 0;
  DateTime? _lastBottomPreviewUpdateAt;
  int? _pendingBottomPreviewPage;
  int? _lastWarmUpCenterPage;
  int _readerWarmUpGeneration = 0;

  @override
  void initState() {
    super.initState();

    _anchorAyahKey = _initialAnchorAyahKey();
    _selectedPageNumber = widget.initialPage.clamp(1, 604);
    _lastMushafPageNumber = _selectedPageNumber;
    _hideMode = widget.initialHideMode;
    _bottomBarSnapshotNotifier = ValueNotifier<_QpcBottomBarSnapshot>(
      _bottomBarSnapshotForPage(_selectedPageNumber),
    );
    _pageMetadataNotifier = ValueNotifier<SvgMushafPageMetadata?>(null);

    _pageController = PageController(
      initialPage: _mushafPageIndex(_selectedPageNumber),
    );

    unawaited(_syncPageMetadata(_selectedPageNumber));
    unawaited(_syncInitialPageFromAnchor());
    _warmUpReaderAssets(_selectedPageNumber, reason: 'init');

    unawaited(_themeController.init());
    unawaited(_audioService.player.setVolume(_volume));

    _positionSubscription = _audioService.positionStream.listen(
      _handleAudioPosition,
    );

    _playerStateSubscription = _audioService.playerStateStream.listen(
      _handlePlayerState,
    );

    _restartControlsAutoHideTimer();
  }

  _QpcBottomBarSnapshot _bottomBarSnapshotForPage(
    int pageNumber, {
    QpcAyahKey? ayahKey,
  }) {
    final int safePage = pageNumber.clamp(1, 604).toInt();
    final QpcAyahKey displayAyah = ayahKey ?? _pageStartAyahKey(safePage);

    return _QpcBottomBarSnapshot(
      pageNumber: safePage,
      surahName: QuranReaderHelpers.getSuraName(
        (displayAyah.surah - 1).clamp(0, 113).toInt(),
      ),
      ayahNumber: displayAyah.ayah,
      juzNumber: QuranReaderHelpers.getJuzNumber(
        suraIndex: (displayAyah.surah - 1).clamp(0, 113).toInt(),
        ayahIndex: (displayAyah.ayah - 1).clamp(0, 286).toInt(),
      ),
    );
  }

  @override
  void dispose() {
    final _QpcPendingReadingPersistence? pendingPersistence =
        _pendingReadingPersistence;
    if (pendingPersistence != null) {
      unawaited(_flushReadingPersistence(pendingPersistence));
    }

    _controlsTimer?.cancel();
    _autoNextTimer?.cancel();
    _previewUpdateTimer?.cancel();
    _readingPersistenceTimer?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _bottomBarSnapshotNotifier.dispose();
    _pageMetadataNotifier.dispose();
    unawaited(_audioService.stop());
    _pageController.dispose();
    super.dispose();
  }

  /// البحث بالنص عبر API مجانية

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        final QuranReaderTheme theme = _themeController.theme;
        final QpcAyahKey? audioTargetAyah = _currentAudioTargetAyah();
        final bool showAudioBar =
            _audioPanelVisible && (audioTargetAyah != null || _isAudioLoading);
        final Size screenSize = MediaQuery.sizeOf(context);
        final bool isLargeReader = screenSize.width >= 600;

        return Scaffold(
          backgroundColor: theme.pageBackground,
          body: SafeArea(
            child: isLargeReader
                ? _buildLargeReaderLayout(
                    context: context,
                    theme: theme,
                    audioTargetAyah: audioTargetAyah,
                    showAudioBar: showAudioBar,
                  )
                : _buildPhoneReaderLayout(
                    context: context,
                    theme: theme,
                    audioTargetAyah: audioTargetAyah,
                    showAudioBar: showAudioBar,
                  ),
          ),
        );
      },
    );
  }
}
