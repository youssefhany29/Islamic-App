import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_category_model.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_item_model.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_data_service.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_progress_service.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_item_details_page.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_home_page.dart';
import 'package:islamic_app/features/quran/quran_page.dart';
import 'package:islamic_app/features/quran/reader/qpc_connected_mushaf_page.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_storage.dart';
import 'package:islamic_app/features/quran/stats/quran_reading_stats_storage.dart';
import 'package:islamic_app/features/quran/wird/daily_wird_page.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_progress_storage.dart';
import 'package:islamic_app/features/quran/wird/quran_wird_storage.dart';
import 'package:islamic_app/features/recitations/pages/recitations_home_page.dart';
import 'package:islamic_app/features/recitations/services/recitation_audio_controller.dart';
import 'package:islamic_app/features/recitations/services/recitation_progress_storage.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import '../../../../memorization/data/models/memorization_session_result_model.dart';

class PhoneContinueJourneyCarousel extends StatefulWidget {
  const PhoneContinueJourneyCarousel({
    super.key,
    this.onJourneyChanged,
  });

  final Future<void> Function()? onJourneyChanged;

  @override
  State<PhoneContinueJourneyCarousel> createState() =>
      _PhoneContinueJourneyCarouselState();
}

class _PhoneContinueJourneyCarouselState
    extends State<PhoneContinueJourneyCarousel> {
  static const int _mushafPagesCount = 604;

  final PageController _pageController = PageController(viewportFraction: 0.78);

  int _currentIndex = 0;
  bool _isLoading = true;
  List<_JourneyItem> _items = const [];

  QuranLastRead? _lastRead;
  int _lastReadPage = 0;
  int _lastReadGlobalAyahIndex = 0;
  String? _lastRandomZekrItemId;

  @override
  void initState() {
    super.initState();
    _loadJourneyItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadJourneyItems() async {
    final quranStats = await QuranReadingStatsStorage.getStats();
    final lastReadItem = await _buildLastReadItem(quranStats);
    final wirdItem = await _buildWirdItem();
    final recitationItem = await _buildRecitationItem();
    final azkarItem = await _buildZekrItem();
    final memorizationItem = await _buildMemorizationItem();

    final items = <_JourneyItem>[
      lastReadItem,
      wirdItem,
      recitationItem,
      azkarItem,
      memorizationItem,
    ];

    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;

      if (_currentIndex >= items.length) {
        _currentIndex = 0;
      }
    });
  }

  Future<_JourneyItem> _buildLastReadItem(QuranReadingStats quranStats) async {
    final lastRead = await QuranReaderStorage.getLastRead();
    final int totalReadPages = quranStats.totalReadPages
        .clamp(0, _mushafPagesCount)
        .toInt();

    if (lastRead == null) {
      _lastRead = null;
      _lastReadPage = 0;
      _lastReadGlobalAyahIndex = 0;

      return _JourneyItem(
        title: 'أكمل تلاوتك',
        subtitle: 'افتح المصحف وسجّل أول موضع قراءة',
        icon: Icons.menu_book_rounded,
        progress: 0,
        bottomText: 'ابدأ الآن',
        onTap: _openLastRead,
      );
    }

    final int globalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: lastRead.suraIndex,
      ayahIndex: lastRead.ayahIndex,
    );

    final int pageNumber = lastRead.mushafPageNumber > 0
        ? lastRead.mushafPageNumber.clamp(1, _mushafPagesCount).toInt()
        : QuranPageMapper.getPageNumberForGlobalAyah(globalAyahIndex);

    final String suraName = QuranWirdStorage.getSuraName(lastRead.suraIndex);
    final String ayahNumber = _arabicNumber(lastRead.ayahIndex + 1);
    final String pageText = _arabicNumber(pageNumber);

    _lastRead = lastRead;
    _lastReadPage = pageNumber;
    _lastReadGlobalAyahIndex = globalAyahIndex;

    return _JourneyItem(
      title: 'أكمل تلاوتك',
      subtitle: '$suraName • آية $ayahNumber • صفحة $pageText',
      icon: Icons.menu_book_rounded,
      progress: pageNumber / _mushafPagesCount,
      bottomText: totalReadPages == 0
          ? 'تابع من آخر موضع'
          : 'قرأت ${_arabicNumber(totalReadPages)} صفحة إجماليًا',
      onTap: _openLastRead,
    );
  }

  Future<_JourneyItem> _buildWirdItem() async {
    final activeWirds = await QuranWirdStorage.buildTodayWirds();

    if (activeWirds.isEmpty) {
      return _JourneyItem(
        title: 'ابدأ وردك اليومي',
        subtitle: 'أنشئ خطة ختمة وحدد مقدارك اليومي',
        icon: Icons.auto_stories_rounded,
        progress: 0,
        bottomText: 'إنشاء ورد',
        onTap: () => _openPage(const DailyWirdPage()),
      );
    }

    final wird = activeWirds.first;
    final completedToday = await QuranWirdProgressStorage.wasCompletedToday(
      wird.planId,
    );

    final int totalAyahs =
    (wird.toGlobalAyahIndex - wird.fromGlobalAyahIndex + 1)
        .clamp(1, QuranReaderHelpers.totalAyahs)
        .toInt();

    if (completedToday) {
      return _JourneyItem(
        title: 'أتممت ورد اليوم',
        subtitle: 'بارك الله في يومك، موعدك غدًا مع ورد جديد',
        icon: Icons.verified_rounded,
        progress: 1,
        bottomText: 'مكتمل',
        onTap: () => _openPage(const DailyWirdPage()),
      );
    }

    final progress = await QuranWirdProgressStorage.getProgress(wird.planId);

    if (progress == null) {
      return _JourneyItem(
        title: 'ابدأ ورد اليوم',
        subtitle:
        '${QuranWirdStorage.getSuraName(wird.fromSuraIndex)} إلى ${QuranWirdStorage.getSuraName(wird.toSuraIndex)}',
        icon: Icons.auto_stories_rounded,
        progress: 0,
        bottomText: '${_arabicNumber(totalAyahs)} آية',
        onTap: () => _openPage(const DailyWirdPage()),
      );
    }

    final currentGlobalAyahIndex = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: progress.suraIndex,
      ayahIndex: progress.ayahIndex,
    ).clamp(wird.fromGlobalAyahIndex, wird.toGlobalAyahIndex).toInt();

    final completedAyahs = (currentGlobalAyahIndex - wird.fromGlobalAyahIndex)
        .clamp(0, totalAyahs)
        .toInt();
    final remainingAyahs = (totalAyahs - completedAyahs)
        .clamp(0, totalAyahs)
        .toInt();

    return _JourneyItem(
      title: 'وردك لم يكتمل بعد',
      subtitle: 'باقي لك ${_arabicNumber(remainingAyahs)} آية على ورد اليوم',
      icon: Icons.auto_stories_rounded,
      progress: completedAyahs / totalAyahs,
      bottomText:
      '${_arabicNumber(completedAyahs)} / ${_arabicNumber(totalAyahs)} آية',
      onTap: () => _openPage(const DailyWirdPage()),
    );
  }

  Future<_JourneyItem> _buildRecitationItem() async {
    final last = await RecitationProgressStorage.getLastRecitation();

    if (last == null) {
      return _JourneyItem(
        title: 'تابع استماعك',
        subtitle: 'اختر قارئك المفضل وابدأ رحلة سماع القرآن',
        icon: Icons.headphones_rounded,
        progress: 0,
        bottomText: 'ابدأ الآن',
        onTap: () => _openPage(const RecitationsHomePage()),
        isLiveRecitation: true,
      );
    }

    final String surahName = last['surahName']?.toString().trim() ?? '';
    final String reciterName = last['reciterName']?.toString().trim() ?? '';

    final int positionSeconds = last['positionSeconds'] is int
        ? last['positionSeconds'] as int
        : 0;

    final int durationSeconds = last['durationSeconds'] is int
        ? last['durationSeconds'] as int
        : 0;

    final double progress = durationSeconds <= 0
        ? 0
        : (positionSeconds / durationSeconds).clamp(0.0, 1.0).toDouble();

    final String bottomText = [
      if (reciterName.isNotEmpty) reciterName,
      if (surahName.isNotEmpty) surahName,
    ].join(' • ');

    return _JourneyItem(
      title: 'تابع استماعك',
      subtitle: positionSeconds > 0
          ? 'أكمل من آخر موضع توقفت عنده ${_formatSeconds(positionSeconds)}'
          : 'أكمل من آخر سورة استمعت إليها',
      icon: Icons.headphones_rounded,
      progress: progress,
      bottomText: bottomText.isEmpty ? 'استكمال الاستماع' : bottomText,
      onTap: () => _openPage(const RecitationsHomePage()),
      isLiveRecitation: true,
    );
  }

  Future<_JourneyItem> _buildZekrItem() async {
    const progressService = ZekrProgressService();
    final completedItems = await progressService.getCompletedItemsToday();
    final targetItems = _dailyZekrTargetItems();
    final completed = completedItems.length.clamp(0, targetItems).toInt();
    final bool isMorning = DateTime.now().hour >= 4 && DateTime.now().hour < 16;
    final bool isCompleted = completed >= targetItems;

    return _JourneyItem(
      title: isCompleted
          ? 'أتممت أذكار اليوم'
          : isMorning
          ? 'أذكار الصباح'
          : 'أذكار المساء',
      subtitle: isCompleted
          ? 'حصّنت يومك بفضل الله'
          : completed == 0
          ? isMorning
          ? 'ابدأ يومك بذكر يطمئن قلبك'
          : 'اختم يومك بسكينة وطمأنينة'
          : 'أنجزت ${_arabicNumber(completed)} من ${_arabicNumber(targetItems)} ذكر اليوم',
      icon: Icons.self_improvement_rounded,
      progress: completed / targetItems,
      bottomText: isCompleted
          ? 'مكتمل'
          : '${_arabicNumber(completed)} / ${_arabicNumber(targetItems)} ذكر',
      onTap: _openRandomZekr,
    );
  }

  Future<_JourneyItem> _buildMemorizationItem() async {
    final activePlan = await MemorizationPlanStorage.getActivePlan();
    final todayTask = await MemorizationPlanStorage.getTodayTask();
    final todayCompletedResult = await _getTodayMemorizationResult(
      task: todayTask,
    );

    if (todayCompletedResult != null) {
      return _JourneyItem(
        title: 'أتممت حفظ اليوم',
        subtitle: 'أحسنت، تم تسجيل مهمة الحفظ لهذا اليوم',
        icon: Icons.verified_rounded,
        progress: 1,
        bottomText: 'مكتمل',
        onTap: () => _openPage(const MemorizationHomePage()),
      );
    }

    if (activePlan == null || todayTask == null) {
      return _JourneyItem(
        title: 'ابدأ رحلة الحفظ',
        subtitle: 'اختر سورة صغيرة وابدأ بخطوة بسيطة',
        icon: Icons.workspace_premium_rounded,
        progress: 0,
        bottomText: 'إنشاء خطة',
        onTap: () => _openPage(const MemorizationHomePage()),
      );
    }

    if (todayTask.isFutureTask) {
      return _JourneyItem(
        title: 'مراجعة الحفظ قادمة',
        subtitle: todayTask.scopeTitle,
        icon: Icons.workspace_premium_rounded,
        progress: 0,
        bottomText: activePlan.planName,
        onTap: () => _openPage(const MemorizationHomePage()),
      );
    }

    final bool isCompleted = todayTask.isCompleted ||
        todayTask.status == MemorizationTodayTaskModel.statusCompleted;

    return _JourneyItem(
      title: isCompleted ? 'أتممت حفظ اليوم' : 'راجع حفظك',
      subtitle: isCompleted
          ? 'أحسنت، استمر على نفس الهدوء والثبات'
          : todayTask.scopeTitle.trim().isEmpty
          ? 'مراجعة قصيرة تثبّت ما حفظته'
          : todayTask.scopeTitle,
      icon: isCompleted ? Icons.verified_rounded : Icons.workspace_premium_rounded,
      progress: isCompleted ? 1 : _memorizationProgress(todayTask),
      bottomText: isCompleted
          ? 'مكتمل'
          : '${_arabicNumber(todayTask.ayahsCount)} آية • ${todayTask.statusTitle}',
      onTap: () => _openPage(const MemorizationHomePage()),
    );
  }

  Future<MemorizationSessionResultModel?> _getTodayMemorizationResult({
    MemorizationTodayTaskModel? task,
  }) async {
    final results = await MemorizationSessionResultStorage.getResults();
    final now = DateTime.now();

    for (final result in results) {
      if (!_isSameDay(result.completedAt, now)) continue;
      if (result.completedStep != 'completed') continue;
      if (result.taskType == 'weakReview') continue;

      if (task == null) return result;

      final exactTask = result.taskId == task.id;
      final sameRange = result.startGlobalAyahIndex == task.startGlobalAyahIndex &&
          result.endGlobalAyahIndex == task.endGlobalAyahIndex;
      final compatibleType = result.taskType == task.type ||
          (task.type == 'dailyNew' && result.taskType == 'dailyReview') ||
          (task.type == 'dailyReview' && result.taskType == 'dailyNew');

      if (exactTask || sameRange || compatibleType) {
        return result;
      }
    }

    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _memorizationProgress(MemorizationTodayTaskModel task) {
    if (task.isCompleted ||
        task.status == MemorizationTodayTaskModel.statusCompleted) {
      return 1;
    }

    switch (task.status) {
      case MemorizationTodayTaskModel.statusSelfTestDone:
        return 0.86;
      case MemorizationTodayTaskModel.statusReadyForTest:
        return 0.68;
      case MemorizationTodayTaskModel.statusReading:
        return 0.35;
      case MemorizationTodayTaskModel.statusNotStarted:
      default:
        return 0;
    }
  }


  Future<void> _openRandomZekr() async {
    AppHaptics.tap(context);

    final selection = await _pickRandomZekrSelection();

    if (selection == null) return;

    final bool? changed = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ZekrItemDetailsPage(
          category: selection.category,
          item: selection.item,
          items: <ZekrItemModel>[selection.item],
          initialIndex: 0,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted) return;

    _lastRandomZekrItemId = selection.item.id;

    if (changed == true) {
      await _loadJourneyItems();
    } else {
      await _loadJourneyItems();
    }

    await widget.onJourneyChanged?.call();
  }

  Future<_RandomZekrSelection?> _pickRandomZekrSelection() async {
    final dataService = ZekrDataService();
    const progressService = ZekrProgressService();

    final selections = <_RandomZekrSelection>[];
    final incompleteSelections = <_RandomZekrSelection>[];

    for (final category in ZekrLocalData.categories) {
      if (!category.isDailyTarget) continue;

      final items = await dataService.getItemsByCategory(category.id);

      for (final item in items) {
        final selection = _RandomZekrSelection(
          category: category,
          item: item,
        );

        selections.add(selection);

        final isCompleted = await progressService.isItemCompletedToday(
          categoryId: category.id,
          itemId: item.id,
        );

        if (!isCompleted) {
          incompleteSelections.add(selection);
        }
      }
    }

    final source = incompleteSelections.isNotEmpty
        ? incompleteSelections
        : selections;

    if (source.isEmpty) return null;

    final filtered = source.length == 1
        ? source
        : source
        .where((selection) => selection.item.id != _lastRandomZekrItemId)
        .toList();

    final pool = filtered.isEmpty ? source : filtered;
    return pool[math.Random().nextInt(pool.length)];
  }

  int _dailyZekrTargetItems() {
    int targetItems = 0;

    for (final category in ZekrLocalData.categories) {
      if (!category.isDailyTarget) continue;
      targetItems += ZekrLocalData.getBuiltInItems(category.id).length;
    }

    return targetItems <= 0 ? 1 : targetItems;
  }

  Future<void> _openLastRead() async {
    AppHaptics.tap(context);

    if (_lastRead == null || _lastReadPage <= 0) {
      await _openPage(const QuranPage());
      return;
    }

    await _openPage(
      QpcConnectedMushafPage(
        initialPage: _lastReadPage,
        initialGlobalAyahIndex: _lastReadGlobalAyahIndex,
        saveAsLastRead: true,
        saveAsMushafOpenProgress: true,
      ),
    );
  }

  Future<void> _openPage(Widget page) async {
    AppHaptics.tap(context);

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    await _loadJourneyItems();
    await widget.onJourneyChanged?.call();
  }

  String _arabicNumber(Object value) {
    return _arabicDigits(value);
  }

  String _formatSeconds(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;

    return '${_arabicNumber(minutes)}:${_arabicNumber(seconds.toString().padLeft(2, '0'))}';
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        height: 128.h,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: AppLayoutConstants.mainCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 128.h,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: _onPageChanged,
                padEnds: true,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isActive = index == _currentIndex;

                  return AnimatedScale(
                    scale: isActive ? 1 : 0.96,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: _JourneyCard(
                        item: item,
                        isActive: isActive,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            _JourneyDots(
              count: _items.length,
              currentIndex: _currentIndex,
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.item,
    required this.isActive,
  });

  final _JourneyItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color textColor = colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: item.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 13.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isActive
                  ? colors.primary.withOpacity(0.30)
                  : textColor.withOpacity(0.06),
              width: 0.9.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.055),
                blurRadius: isActive ? 16.r : 9.r,
                offset: Offset(0, isActive ? 7.h : 4.h),
              ),
            ],
          ),
          child: _BasicCardContent(item: item, textColor: textColor),
        ),
      ),
    );
  }
}

class _BasicCardContent extends StatelessWidget {
  const _BasicCardContent({
    required this.item,
    required this.textColor,
  });

  final _JourneyItem item;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final double safeProgress = item.progress.clamp(0.0, 1.0).toDouble();

    if (item.isLiveRecitation) {
      return StreamBuilder<RecitationAudioState>(
        stream: RecitationAudioController.instance.audioStateStream,
        builder: (context, snapshot) {
          final live = _liveRecitationSnapshot(item, snapshot.data);
          return _buildContent(
            context: context,
            item: live.item,
            textColor: textColor,
            colors: colors,
            safeProgress: live.progress,
          );
        },
      );
    }

    return _buildContent(
      context: context,
      item: item,
      textColor: textColor,
      colors: colors,
      safeProgress: safeProgress,
    );
  }

  _LiveRecitationCardData _liveRecitationSnapshot(
      _JourneyItem fallback,
      RecitationAudioState? state,
      ) {
    final currentInfo = RecitationAudioController.instance.currentInfo;

    if (currentInfo == null) {
      return _LiveRecitationCardData(
        item: fallback,
        progress: fallback.progress.clamp(0.0, 1.0).toDouble(),
      );
    }

    final int positionSeconds =
        state?.position.inSeconds ??
            RecitationAudioController.instance.player.position.inSeconds;
    final int durationSeconds =
        state?.duration.inSeconds ??
            RecitationAudioController.instance.player.duration?.inSeconds ??
            0;

    final double progress = durationSeconds <= 0
        ? 0
        : (positionSeconds / durationSeconds).clamp(0.0, 1.0).toDouble();

    return _LiveRecitationCardData(
      item: fallback.copyWith(
        subtitle: positionSeconds > 0
            ? 'الآن ${_formatSeconds(positionSeconds)} من ${_formatSeconds(durationSeconds)}'
            : 'يعمل الآن',
        bottomText: [
          currentInfo.reciterName,
          currentInfo.surahName,
        ].where((value) => value.trim().isNotEmpty).join(' • '),
      ),
      progress: progress,
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required _JourneyItem item,
    required Color textColor,
    required ColorScheme colors,
    required double safeProgress,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBubble(icon: item.icon),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        color: textColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor.withOpacity(0.58),
                        fontSize: 7.8.sp,
                        fontWeight: FontWeight.w400,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 5.h,
              backgroundColor: textColor.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Icon(
                Icons.chevron_right_rounded,
                size: 16.sp,
                color: colors.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.bottomText ?? '${_arabicDigits((safeProgress * 100).round())}%',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.primary,
                    fontSize: 8.4.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;

    return '${_arabicDigits(minutes)}:${_arabicDigits(seconds.toString().padLeft(2, '0'))}';
  }
}

class _LiveRecitationCardData {
  const _LiveRecitationCardData({
    required this.item,
    required this.progress,
  });

  final _JourneyItem item;
  final double progress;
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18.sp,
        color: colors.primary,
      ),
    );
  }
}

class _JourneyDots extends StatelessWidget {
  const _JourneyDots({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(context).colorScheme.surface.withOpacity(0.18);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: List.generate(count, (index) {
        final active = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: active ? 20.w : 6.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(99.r),
          ),
        );
      }),
    );
  }
}


class _RandomZekrSelection {
  const _RandomZekrSelection({
    required this.category,
    required this.item,
  });

  final ZekrCategoryModel category;
  final ZekrItemModel item;
}

class _JourneyItem {
  const _JourneyItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.onTap,
    this.bottomText,
    this.isLiveRecitation = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double progress;
  final VoidCallback onTap;
  final String? bottomText;
  final bool isLiveRecitation;

  _JourneyItem copyWith({
    String? title,
    String? subtitle,
    IconData? icon,
    double? progress,
    VoidCallback? onTap,
    String? bottomText,
    bool? isLiveRecitation,
  }) {
    return _JourneyItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      progress: progress ?? this.progress,
      onTap: onTap ?? this.onTap,
      bottomText: bottomText ?? this.bottomText,
      isLiveRecitation: isLiveRecitation ?? this.isLiveRecitation,
    );
  }
}

String _arabicDigits(Object value) {
  return value
      .toString()
      .replaceAll('0', '0')
      .replaceAll('1', '1')
      .replaceAll('2', '2')
      .replaceAll('3', '3')
      .replaceAll('4', '4')
      .replaceAll('5', '5')
      .replaceAll('6', '6')
      .replaceAll('7', '7')
      .replaceAll('8', '8')
      .replaceAll('9', '9');
}
