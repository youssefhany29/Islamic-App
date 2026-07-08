import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/reciter_model.dart';
import '../services/recitation_api_service.dart';
import '../services/recitation_audio_controller.dart';
import '../services/recitation_download_service.dart';
import '../services/recitation_favorites_storage.dart';
import '../services/recitation_listening_history_storage.dart';
import '../services/recitation_listening_stats_storage.dart';
import '../services/recitation_progress_storage.dart';
import 'downloaded_recitations_page.dart';
import 'recitation_favorites_page.dart';
import 'recitation_listening_goal_page.dart';
import 'recitation_listening_history_page.dart';
import 'recitation_listening_stats_page.dart';
import 'recitation_player_page.dart';
import 'reciter_surahs_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'recitations_home_widgets.dart';

class RecitationsHomePage extends StatefulWidget {
  const RecitationsHomePage({super.key});

  @override
  State<RecitationsHomePage> createState() => _RecitationsHomePageState();
}

class _RecitationsHomePageState extends State<RecitationsHomePage> {
  final TextEditingController searchController = TextEditingController();

  List<ReciterModel> reciters = [];
  String searchText = '';

  bool isLoading = true;
  String? errorText;

  Map<String, dynamic>? lastRecitation;
  RecitationListeningStatsData? listeningStats;

  bool hasDownloads = false;
  bool hasFavorites = false;
  bool hasHistory = false;

  final Map<String, int> downloadedCountByReciter = {};
  final Set<String> favoriteReciterKeys = {};

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _reciterKey(ReciterModel reciter) {
    return '${reciter.source.name}_${reciter.id}';
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadReciters(),
      _loadLastRecitation(),
      _loadListeningStats(),
      _loadDownloadsState(),
      _loadFavoritesState(),
      _loadHistoryState(),
    ]);
  }

  Future<void> _refreshAfterChildPage() async {
    await Future.wait([
      _loadLastRecitation(),
      _loadListeningStats(),
      _loadDownloadsState(),
      _loadFavoritesState(),
      _loadHistoryState(),
    ]);
  }

  Future<void> _loadReciters() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorText = null;
      });
    }

    try {
      final loadedReciters = await RecitationApiService.getReciters();

      if (!mounted) return;

      setState(() {
        reciters = loadedReciters;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('❌ Failed to load reciters: $error');

      if (!mounted) return;

      setState(() {
        errorText = 'خدمة التلاوات غير متاحة مؤقتًا، حاول مرة أخرى بعد قليل';
        isLoading = false;
      });
    }
  }

  Future<void> _loadLastRecitation() async {
    final saved = await RecitationProgressStorage.getLastRecitation();

    if (!mounted) return;

    setState(() {
      lastRecitation = saved;
    });
  }

  Future<void> _loadListeningStats() async {
    final stats = await RecitationListeningStatsStorage.loadStats();

    if (!mounted) return;

    setState(() {
      listeningStats = stats;
    });
  }

  Future<void> _loadDownloadsState() async {
    final downloads = await RecitationDownloadService.getAllDownloads();

    final countMap = <String, int>{};

    for (final download in downloads) {
      final key = '${download.reciterSource.name}_${download.reciterId}';
      countMap[key] = (countMap[key] ?? 0) + 1;
    }

    if (!mounted) return;

    setState(() {
      hasDownloads = downloads.isNotEmpty;
      downloadedCountByReciter
        ..clear()
        ..addAll(countMap);
    });
  }

  Future<void> _loadFavoritesState() async {
    final favorites = await RecitationFavoritesStorage.loadFavorites();

    final reciterKeys = favorites
        .where((item) => item.isReciterFavorite)
        .map((item) => '${item.reciterSource.name}_${item.reciterId}')
        .toSet();

    if (!mounted) return;

    setState(() {
      hasFavorites = favorites.isNotEmpty;
      favoriteReciterKeys
        ..clear()
        ..addAll(reciterKeys);
    });
  }

  Future<void> _loadHistoryState() async {
    final history = await RecitationListeningHistoryStorage.loadHistory();

    if (!mounted) return;

    setState(() {
      hasHistory = history.isNotEmpty;
    });
  }

  List<ReciterModel> get filteredReciters {
    final text = searchText.trim();

    if (text.isEmpty) return reciters;

    return reciters.where((reciter) {
      return reciter.name.contains(text) ||
          reciter.translatedName.contains(text) ||
          reciter.qiratName.contains(text);
    }).toList();
  }

  void _openReciter(ReciterModel reciter) {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReciterSurahsPage(reciter: reciter),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  void _openDownloads() {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DownloadedRecitationsPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  void _openFavorites() {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationFavoritesPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  void _openHistory() {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationListeningHistoryPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  void _openListeningStats() {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationListeningStatsPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  void _openGoalPage() {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationListeningGoalPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  Future<void> _toggleReciterFavorite(ReciterModel reciter) async {
    AppHaptics.tap(context);

    await RecitationFavoritesStorage.toggleReciterFavorite(
      reciterId: reciter.id,
      reciterName: reciter.name,
      reciterSource: reciter.source,
      mp3QuranServerUrl: reciter.serverUrl,
    );

    await _loadFavoritesState();
  }

  void _openLastRecitation() {
    final audioController = RecitationAudioController.instance;
    final currentInfo = audioController.currentInfo;

    if (currentInfo != null) {
      AppHaptics.tap(context);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RecitationPlayerPage(
                reciterId: currentInfo.reciterId,
                reciterName: currentInfo.reciterName,
                reciterSource: currentInfo.reciterSource,
                mp3QuranServerUrl: currentInfo.mp3QuranServerUrl,
                surahNumber: currentInfo.surahNumber,
                surahName: currentInfo.surahName,
                initialAudioUrl: currentInfo.audioUrl,
                localFilePath: currentInfo.localFilePath,
                startPosition: audioController.player.position,
              ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      ).then((_) => _refreshAfterChildPage());

      return;
    }

    final saved = lastRecitation;

    if (saved == null) return;

    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecitationPlayerPage(
              reciterId: saved['reciterId'] as int,
              reciterName: saved['reciterName'].toString(),
              reciterSource: saved['reciterSource'] as RecitationSource,
              mp3QuranServerUrl: saved['mp3QuranServerUrl'].toString(),
              surahNumber: saved['surahNumber'] as int,
              surahName: saved['surahName'].toString(),
              initialAudioUrl: saved['audioUrl'].toString(),
              startPosition: Duration(seconds: saved['positionSeconds'] as int),
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _refreshAfterChildPage());
  }

  Future<void> _togglePlayPauseFromCard() async {
    AppHaptics.tap(context);
    await RecitationAudioController.instance.togglePlayPause();
    await _refreshAfterChildPage();
  }

  bool _isCurrentReciter(ReciterModel reciter) {
    final currentInfo = RecitationAudioController.instance.currentInfo;

    if (currentInfo == null) return false;

    return currentInfo.reciterId == reciter.id &&
        currentInfo.reciterSource == reciter.source;
  }

  bool _isLastReciter(ReciterModel reciter) {
    final saved = lastRecitation;

    if (saved == null) return false;

    return saved['reciterId'] == reciter.id &&
        saved['reciterSource'] == reciter.source;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    final hasCurrentAudio =
        RecitationAudioController.instance.currentInfo != null;
    final showContinueCard = hasCurrentAudio || lastRecitation != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              _Header(
                title: 'تلاوة',
                hasFavorites: hasFavorites,
                hasHistory: hasHistory,
                onBack: () {
                  AppHaptics.tap(context);
                  Navigator.pop(context);
                },
                onOpenFavorites: _openFavorites,
                onOpenHistory: _openHistory,
              ),
              if (showContinueCard) ...[
                SizedBox(height: 8.h),
                _ContinueListeningCard(
                  lastRecitation: lastRecitation,
                  onTap: _openLastRecitation,
                  onTogglePlayPause: _togglePlayPauseFromCard,
                ),
              ],
              SizedBox(height: 8.h),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'إحصائياتي',
                      icon: Icons.insights_rounded,
                      onTap: _openListeningStats,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'هدفي اليومي',
                      icon: Icons.track_changes_rounded,
                      onTap: _openGoalPage,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'تنزيلاتي',
                      icon: Icons.download_done_rounded,
                      onTap: _openDownloads,
                      muted: !hasDownloads,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7.h),
              Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xff171B26)
                      : primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.14)
                        : primary.withOpacity(0.16),
                    width: 0.9.w,
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'ابحث عن قارئ',
                          hintStyle: AppTextStyles.caption(context).copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.45)
                                : textColor.withOpacity(0.45),
                          ),
                        ),
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: textColor),
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                      ),
                    ),
                    Icon(
                      Icons.search_rounded,
                      size: 18.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.65)
                          : textColor.withOpacity(0.65),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : errorText != null
                    ? _ErrorView(text: errorText!, onRetry: _loadReciters)
                    : filteredReciters.isEmpty
                    ? const _EmptyView(text: 'لا توجد نتائج')
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _refreshAll,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredReciters.length,
                          separatorBuilder: (_, __) => SizedBox(height: 7.h),
                          itemBuilder: (context, index) {
                            final reciter = filteredReciters[index];
                            final key = _reciterKey(reciter);

                            return _ReciterTile(
                              reciter: reciter,
                              downloadedCount:
                                  downloadedCountByReciter[key] ?? 0,
                              isFavorite: favoriteReciterKeys.contains(key),
                              isCurrent: _isCurrentReciter(reciter),
                              isLast: _isLastReciter(reciter),
                              onTap: () => _openReciter(reciter),
                              onToggleFavorite: () {
                                _toggleReciterFavorite(reciter);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
