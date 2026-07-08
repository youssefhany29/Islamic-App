import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/presentation/widgets/mastery_empty_state_line.dart';
import '../pages/memorization_training_session_page.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_weak_spots_engine.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationWeakSpotsPage extends StatefulWidget {
  const MemorizationWeakSpotsPage({super.key});

  @override
  State<MemorizationWeakSpotsPage> createState() =>
      _MemorizationWeakSpotsPageState();
}

class _MemorizationWeakSpotsPageState extends State<MemorizationWeakSpotsPage> {
  Future<List<MemorizationWeakSpotModel>>? weakSpotsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    weakSpotsFuture = const MemorizationWeakSpotsEngine().getWeakSpots();
  }

  Future<void> _openRescueSession(MemorizationWeakSpotModel weakSpot) async {
    AppHaptics.tap(context);

    final task = const MemorizationWeakSpotsEngine().buildRescueTaskFromWeakSpot(
      weakSpot,
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemorizationTrainingSessionPage(task: task),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(_reload);
    }
  }

  String _lastSeenText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff <= 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    if (diff == 2) return 'منذ يومين';
    if (diff <= 10) return 'منذ $diff أيام';
    return 'منذ $diff يوم';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              category: CustomAppBarCategory(text: 'مواضعي الضعيفة'),
            ),
            Expanded(
              child: FutureBuilder<List<MemorizationWeakSpotModel>>(
                future: weakSpotsFuture,
                builder: (context, snapshot) {
                  final weakSpots =
                      snapshot.data ?? const <MemorizationWeakSpotModel>[];

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _WeakSpotsHeader(count: weakSpots.length),
                        SizedBox(height: 14.h),
                        if (weakSpots.isEmpty)
                          const _EmptyWeakSpotsCard()
                        else
                          ...weakSpots.map(
                                (weakSpot) => Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: _WeakSpotTile(
                                weakSpot: weakSpot,
                                lastSeenText: _lastSeenText(
                                  weakSpot.lastSeenAt,
                                ),
                                onTap: () => _openRescueSession(weakSpot),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakSpotsHeader extends StatelessWidget {
  const _WeakSpotsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ذاكرة المواضع الضعيفة',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25
),
          ),
          SizedBox(height: 6.h),
          Text(
            count == 0
                ? 'أي مقطع تقيمه صعب أو نسيت سيظهر هنا تلقائيًا.'
                : 'عندك $count موضع يحتاج تثبيت. ابدأ الإنقاذ من الموضع الأهم.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.76),
              height: 1.45
),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Text(
              'لو تحسن الموضع واخترت سهل أو جيد، سيخرج تلقائيًا من هذه الصفحة.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.84),
                height: 1.4
),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWeakSpotsCard extends StatelessWidget {
  const _EmptyWeakSpotsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: const MasteryEmptyStateLine(
        icon: Icons.verified_rounded,
        title: 'لا توجد مواضع ضعيفة الآن',
        subtitle: 'استمر في التقييم بصدق. أي موضع صعب أو منسي سيظهر هنا للإنقاذ.',
      ),
    );
  }
}

class _WeakSpotTile extends StatelessWidget {
  const _WeakSpotTile({
    required this.weakSpot,
    required this.lastSeenText,
    required this.onTap,
  });

  final MemorizationWeakSpotModel weakSpot;
  final String lastSeenText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(13.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Icon(
                      weakSpot.isForgotten
                          ? Icons.refresh_rounded
                          : Icons.warning_amber_rounded,
                      color: theme.colorScheme.primary,
                      size: 23.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          weakSpot.scopeTitle,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                            color: theme.colorScheme.surface,
                            height: 1.3
),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          weakSpot.shortReason,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                            color: theme.colorScheme.surface.withOpacity(0.58),
                            height: 1.35
),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 7.w,
                runSpacing: 7.h,
                alignment: WrapAlignment.end,
                children: [
                  _WeakSpotBadge(text: weakSpot.ratingTitle),
                  _WeakSpotBadge(text: '${weakSpot.ayahsCount} آية'),
                  _WeakSpotBadge(text: '$lastSeenText'),
                  _WeakSpotBadge(text: '${weakSpot.attemptsCount} محاولة'),
                  if (weakSpot.rescueSessionsCount > 0)
                    _WeakSpotBadge(text: '${weakSpot.rescueSessionsCount} إنقاذ'),
                ],
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.healing_rounded,
                        color: theme.colorScheme.primary,
                        size: 15.sp,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'ابدأ إنقاذ',
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          height: 1
),
                      ),
                    ],
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

class _WeakSpotBadge extends StatelessWidget {
  const _WeakSpotBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
          height: 1
),
      ),
    );
  }
}
