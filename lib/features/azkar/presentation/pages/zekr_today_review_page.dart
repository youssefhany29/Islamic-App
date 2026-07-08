import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/azkar/data/models/zekr_item_model.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_memory_attempt_model.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_memory_item_state_model.dart';
import 'package:islamic_app/features/azkar/data/notifications/zekr_notification_scheduler.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_data_service.dart';
import 'package:islamic_app/features/azkar/data/services/zekr_memory_progress_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

bool _todayReviewLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class _TodayReviewMetrics {
  const _TodayReviewMetrics({
    required this.large,
    required this.pagePadding,
    required this.gap,
    required this.cardPadding,
    required this.cardRadius,
    required this.iconBox,
    required this.iconSize,
    required this.titleSize,
    required this.subtitleSize,
    required this.bodySize,
    required this.answerSize,
    required this.buttonHeight,
    required this.maxWidth,
  });

  final bool large;
  final double pagePadding;
  final double gap;
  final double cardPadding;
  final double cardRadius;
  final double iconBox;
  final double iconSize;
  final double titleSize;
  final double subtitleSize;
  final double bodySize;
  final double answerSize;
  final double buttonHeight;
  final double maxWidth;

  static _TodayReviewMetrics of(BuildContext context) {
    final bool large = _todayReviewLargeScreen(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool compactLarge = large && size.width < 900;

    if (large) {
      return _TodayReviewMetrics(
        large: true,
        pagePadding: compactLarge ? 20 : 28,
        gap: compactLarge ? 12 : 16,
        cardPadding: compactLarge ? 15 : 18,
        cardRadius: 24,
        iconBox: compactLarge ? 42 : 46,
        iconSize: compactLarge ? 22 : 24,
        titleSize: compactLarge ? 16 : 18,
        subtitleSize: compactLarge ? 11 : 12,
        bodySize: compactLarge ? 13 : 14,
        answerSize: compactLarge ? 16 : 17,
        buttonHeight: compactLarge ? 44 : 46,
        maxWidth: compactLarge ? 860 : 980,
      );
    }

    return _TodayReviewMetrics(
      large: false,
      pagePadding: 14.w,
      gap: 12.h,
      cardPadding: 14.w,
      cardRadius: 20.r,
      iconBox: 42.w,
      iconSize: 22.sp,
      titleSize: 15.sp,
      subtitleSize: 10.5.sp,
      bodySize: 12.sp,
      answerSize: 14.sp,
      buttonHeight: 48.h,
      maxWidth: double.infinity,
    );
  }
}

class ZekrTodayReviewPage extends StatefulWidget {
  const ZekrTodayReviewPage({super.key});

  @override
  State<ZekrTodayReviewPage> createState() => _ZekrTodayReviewPageState();
}

class _ZekrTodayReviewPageState extends State<ZekrTodayReviewPage> {
  final ZekrMemoryProgressService _memoryService =
      const ZekrMemoryProgressService();
  final ZekrDataService _dataService = const ZekrDataService();

  late Future<List<ZekrMemoryItemStateModel>> _reviewsFuture;

  List<ZekrMemoryItemStateModel> _reviews = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<List<ZekrMemoryItemStateModel>> _loadReviews() async {
    final reviews = await _memoryService.getDueReviews();
    return reviews;
  }

  Future<ZekrItemModel?> _findItem(ZekrMemoryItemStateModel state) async {
    final items = await _dataService.getItemsByCategory(state.categoryId);

    try {
      return items.firstWhere((item) => item.id == state.itemId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitRating(
    ZekrMemoryRating rating,
    ZekrMemoryItemStateModel state,
  ) async {
    if (_isSaving) return;

    AppHaptics.tap(context);

    setState(() {
      _isSaving = true;
    });

    await _memoryService.saveAttempt(
      ZekrMemoryAttemptModel(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        itemId: state.itemId,
        categoryId: state.categoryId,
        itemTitle: state.itemTitle,
        categoryTitle: state.categoryTitle,
        rating: rating,
        createdAt: DateTime.now(),
        repetitionCount: 1,
        practiceMode: ZekrPracticeMode.test,
      ),
    );

    await const ZekrNotificationScheduler()
        .refreshMemoryReviewReminderFromPrefs();

    if (!mounted) return;

    final bool hasNext = _currentIndex < _reviews.length - 1;

    setState(() {
      _isSaving = false;
      _showAnswer = false;

      if (hasNext) {
        _currentIndex++;
      } else {
        _currentIndex = _reviews.length;
      }
    });

    _showRatingSnackBar(rating);
  }

  void _showRatingSnackBar(ZekrMemoryRating rating) {
    final bool large = _todayReviewLargeScreen(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff171B26),
        duration: const Duration(milliseconds: 1200),
        margin: EdgeInsets.symmetric(
          horizontal: large ? 28 : 18.w,
          vertical: large ? 18 : 14.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(large ? 18 : 16.r),
        ),
        content: Text(
          rating == ZekrMemoryRating.mastered
              ? 'ممتاز، اتسجل كمحفوظ بثقة.'
              : rating == ZekrMemoryRating.partial
              ? 'تمام، هنراجعه قريب للتثبيت.'
              : 'ولا يهمك، هيفضل في خطة المراجعة.',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final reviews = await _loadReviews();

    if (!mounted) return;

    setState(() {
      _reviews = reviews;
      _reviewsFuture = Future.value(reviews);
      _currentIndex = 0;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(text: 'مراجعة اليوم'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<ZekrMemoryItemStateModel>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_reviews.isEmpty && snapshot.hasData) {
              _reviews = snapshot.data ?? [];
            }

            if (_reviews.isEmpty) {
              return _EmptyReviewState(onRefresh: _refresh);
            }

            if (_currentIndex >= _reviews.length) {
              return _CompletedReviewState(
                reviewedCount: _reviews.length,
                onRestart: _refresh,
              );
            }

            final state = _reviews[_currentIndex];

            return FutureBuilder<ZekrItemModel?>(
              future: _findItem(state),
              builder: (context, itemSnapshot) {
                final item = itemSnapshot.data;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      m.pagePadding,
                      m.large ? 12 : 8.h,
                      m.pagePadding,
                      m.large ? 28 : 20.h,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: m.maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _ProgressHeaderCard(
                                current: _currentIndex + 1,
                                total: _reviews.length,
                                state: state,
                              ),
                              SizedBox(height: m.gap),
                              _ReviewQuestionCard(
                                state: state,
                                item: item,
                                showAnswer: _showAnswer,
                                onToggleAnswer: () {
                                  AppHaptics.tap(context);
                                  setState(() {
                                    _showAnswer = !_showAnswer;
                                  });
                                },
                              ),
                              SizedBox(height: m.gap),
                              if (_showAnswer)
                                _RatingActionsCard(
                                  isSaving: _isSaving,
                                  onMastered: () => _submitRating(
                                    ZekrMemoryRating.mastered,
                                    state,
                                  ),
                                  onPartial: () => _submitRating(
                                    ZekrMemoryRating.partial,
                                    state,
                                  ),
                                  onReview: () => _submitRating(
                                    ZekrMemoryRating.review,
                                    state,
                                  ),
                                )
                              else
                                const _ShowAnswerHintCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProgressHeaderCard extends StatelessWidget {
  const _ProgressHeaderCard({
    required this.current,
    required this.total,
    required this.state,
  });

  final int current;
  final int total;
  final ZekrMemoryItemStateModel state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);
    final double progress = total == 0 ? 0.0 : current / total;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.large ? 18 : 14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(m.large ? 24 : 20.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: m.iconBox,
                  height: m.iconBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(m.large ? 15 : 14.r),
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    color: Colors.white,
                    size: m.iconSize,
                  ),
                ),
                SizedBox(width: m.large ? 12 : 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _ArabicText(
                        'مراجعة اليوم',
                        fontSize: m.large ? 18 : 15.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        maxLines: 1,
                      ),
                      SizedBox(height: m.large ? 4 : 3.h),
                      _ArabicText(
                        '$current من $total • قوة الحفظ ${state.memoryStrength.toStringAsFixed(0)}%',
                        fontSize: m.large ? 12 : 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.78),
                        height: 1.4,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: m.large ? 14 : 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: m.large ? 8 : 7.h,
                backgroundColor: Colors.white.withOpacity(0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  const _ReviewQuestionCard({
    required this.state,
    required this.item,
    required this.showAnswer,
    required this.onToggleAnswer,
  });

  final ZekrMemoryItemStateModel state;
  final ZekrItemModel? item;
  final bool showAnswer;
  final VoidCallback onToggleAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);
    final String displayText = item?.text ?? 'لم يتم العثور على نص هذا الذكر.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(m.cardRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ReviewQuestionHeader(state: state),
            SizedBox(height: m.large ? 14 : 12.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(showAnswer),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: m.large ? 16 : 13.w,
                  vertical: m.large ? 16 : 13.h,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(
                    isDark ? 0.14 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(m.large ? 18 : 16.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.14 : 0.08,
                    ),
                  ),
                ),
                child: Text(
                  showAnswer
                      ? displayText
                      : 'اختبر نفسك الآن بدون النظر للنص.\nبعد المحاولة اضغط "إظهار الإجابة" ثم قيّم حفظك.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  locale: const Locale('ar'),
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: showAnswer ? m.answerSize : m.bodySize,
                    fontWeight: showAnswer ? FontWeight.w700 : FontWeight.w600,
                    color: theme.colorScheme.surface,
                    height: showAnswer ? 1.85 : 1.6,
                    letterSpacing: 0,
                    wordSpacing: 0,
                  ),
                ),
              ),
            ),
            SizedBox(height: m.large ? 12 : 12.h),
            SizedBox(
              width: double.infinity,
              height: m.buttonHeight,
              child: OutlinedButton(
                onPressed: onToggleAnswer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(m.large ? 15 : 14.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showAnswer
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: m.large ? 18 : 18.sp,
                    ),
                    SizedBox(width: m.large ? 7 : 6.w),
                    Text(
                      showAnswer ? 'إخفاء الإجابة' : 'إظهار الإجابة',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: m.bodySize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewQuestionHeader extends StatelessWidget {
  const _ReviewQuestionHeader({required this.state});

  final ZekrMemoryItemStateModel state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: m.iconBox,
          height: m.iconBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(m.large ? 15 : 14.r),
          ),
          child: Icon(
            Icons.psychology_alt_outlined,
            color: theme.colorScheme.primary,
            size: m.iconSize,
          ),
        ),
        SizedBox(width: m.large ? 12 : 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ArabicText(
                state.itemTitle,
                fontSize: m.titleSize,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
                height: 1.35,
                maxLines: 2,
              ),
              SizedBox(height: m.large ? 4 : 4.h),
              _ArabicText(
                '${state.categoryTitle} • ${state.level.label} • ${state.reviewDateText}',
                fontSize: m.subtitleSize,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.surface.withOpacity(0.62),
                height: 1.45,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShowAnswerHintCard extends StatelessWidget {
  const _ShowAnswerHintCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.large ? 14 : 12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(m.large ? 18 : 16.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.10)),
      ),
      child: _ArabicText(
        'بعد ما تحاول تسترجع الذكر، اضغط إظهار الإجابة ثم قيّم حفظك.',
        fontSize: m.bodySize,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.surface.withOpacity(0.66),
        height: 1.5,
      ),
    );
  }
}

class _RatingActionsCard extends StatelessWidget {
  const _RatingActionsCard({
    required this.isSaving,
    required this.onMastered,
    required this.onPartial,
    required this.onReview,
  });

  final bool isSaving;
  final VoidCallback onMastered;
  final VoidCallback onPartial;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stackButtons = constraints.maxWidth < 360;

          final buttons = <Widget>[
            _CompactRatingButton(
              title: 'تمام',
              color: const Color(0xff21C58E),
              icon: Icons.verified_rounded,
              enabled: !isSaving,
              onTap: onMastered,
            ),
            _CompactRatingButton(
              title: 'نص نص',
              color: const Color(0xffF59E0B),
              icon: Icons.adjust_rounded,
              enabled: !isSaving,
              onTap: onPartial,
            ),
            _CompactRatingButton(
              title: 'مراجعة',
              color: Theme.of(context).colorScheme.primary,
              icon: Icons.refresh_rounded,
              enabled: !isSaving,
              onTap: onReview,
            ),
          ];

          if (stackButtons) {
            return Column(
              children: [
                SizedBox(width: double.infinity, child: buttons[0]),
                SizedBox(height: m.large ? 8 : 7.h),
                SizedBox(width: double.infinity, child: buttons[1]),
                SizedBox(height: m.large ? 8 : 7.h),
                SizedBox(width: double.infinity, child: buttons[2]),
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SizedBox.expand(child: buttons[0])),
                SizedBox(width: m.large ? 10 : 7.w),
                Expanded(child: SizedBox.expand(child: buttons[1])),
                SizedBox(width: m.large ? 10 : 7.w),
                Expanded(child: SizedBox.expand(child: buttons[2])),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompactRatingButton extends StatelessWidget {
  const _CompactRatingButton({
    required this.title,
    required this.color,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final Color color;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(m.large ? 16 : 15.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(m.large ? 16 : 15.r),
        splashColor: color.withOpacity(0.10),
        highlightColor: color.withOpacity(0.06),
        child: Ink(
          height: m.large ? 54 : 48.h,
          padding: EdgeInsets.symmetric(horizontal: m.large ? 8 : 5.w),
          decoration: BoxDecoration(
            color: color.withOpacity(enabled ? 0.10 : 0.04),
            borderRadius: BorderRadius.circular(m.large ? 16 : 15.r),
            border: Border.all(color: color.withOpacity(enabled ? 0.30 : 0.10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                color: enabled ? color : color.withOpacity(0.35),
                size: m.large ? 18 : 17.sp,
              ),
              SizedBox(width: m.large ? 7 : 5.w),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: enabled
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surface.withOpacity(0.35),
                    height: 1.1,
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

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(m.pagePadding),
        children: [
          SizedBox(height: m.large ? 90 : 80.h),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: m.large ? 620 : double.infinity,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: const Color(0xff21C58E),
                    size: m.large ? 64 : 58.sp,
                  ),
                  SizedBox(height: m.large ? 16 : 14.h),
                  Text(
                    'لا توجد مراجعات اليوم',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.display(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: m.large ? 8 : 6.h),
                  Text(
                    'لو عندك مراجعات قادمة، هتظهر في تقويم المراجعة داخل صفحة الأذكار.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface.withOpacity(0.64),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedReviewState extends StatelessWidget {
  const _CompletedReviewState({
    required this.reviewedCount,
    required this.onRestart,
  });

  final int reviewedCount;
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _TodayReviewMetrics m = _TodayReviewMetrics.of(context);

    return RefreshIndicator(
      onRefresh: onRestart,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(m.pagePadding),
        children: [
          SizedBox(height: m.large ? 90 : 80.h),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: m.large ? 620 : double.infinity,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: const Color(0xff21C58E),
                    size: m.large ? 70 : 64.sp,
                  ),
                  SizedBox(height: m.large ? 16 : 14.h),
                  Text(
                    'أنهيت مراجعة اليوم',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.display(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: m.large ? 8 : 6.h),
                  Text(
                    'راجعت $reviewedCount أذكار. تم تحديث خطة الحفظ والمواعيد القادمة تلقائيًا.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface.withOpacity(0.64),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArabicText extends StatelessWidget {
  const _ArabicText(
    this.text, {
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    this.height,
    this.maxLines,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double? height;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        softWrap: true,
        maxLines: maxLines,
        overflow: maxLines == null
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
