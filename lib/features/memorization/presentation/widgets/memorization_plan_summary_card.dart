import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_plan_preview_model.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class MemorizationPlanSummaryCard extends StatelessWidget {
  const MemorizationPlanSummaryCard({super.key, required this.plan});

  final MemorizationPlanPreviewModel plan;

  String get _cleanDuration {
    final text = plan.durationText.trim();
    if (text.isEmpty) return 'غير محددة';

    final match = RegExp(
      r'([0-9٠-٩]+)\s*(يوم|أيام|أسبوع|أسابيع|اسبوع|شهر|شهور|أشهر)',
    ).firstMatch(text);

    if (match != null) return match.group(0)!.trim();

    return text
        .replaceAll('تقريبًا', '')
        .replaceAll('تقريبا', '')
        .replaceAll('المدة المتوقعة:', '')
        .trim();
  }

  String get _cleanLoad {
    final text = plan.loadText.trim();
    if (text.isEmpty) return 'مريح';

    if (text.contains('مريح')) return 'مريح';
    if (text.contains('متوازن')) return 'متوازن';
    if (text.contains('قوي جدًا')) return 'قوي جدًا';
    if (text.contains('قوي')) return 'قوي';

    return text.length > 12 ? 'مناسب' : text;
  }

  String get _reviewLabel {
    final text = plan.dailyBaseReviewText.trim();
    if (text.isEmpty || text.contains('لا يوجد')) return 'خفيفة';
    if (text.contains('يومي')) return 'يومية';
    return 'مفعّلة';
  }

  bool get _hasNewMemorization {
    final text = plan.dailyNewText.trim();
    return text.isNotEmpty &&
        !text.contains('لا يوجد') &&
        !text.contains('لا يوجد حفظ');
  }

  bool get _hasReview {
    final text = plan.dailyBaseReviewText.trim();
    return text.isNotEmpty && !text.contains('لا يوجد');
  }

  bool get _hasTests {
    final text = plan.selfTestText.trim();
    return text.isNotEmpty && !text.contains('بدون');
  }

  bool get _hasExtraDays {
    final text = plan.durationText;
    return text.contains('زادت') ||
        text.contains('اختبارات') ||
        text.contains('مراجعة');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: theme.colorScheme.primary,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.pathTitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      plan.scopeTitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.learningSessionsCount != plan.targetLearningDays) ...[
            SizedBox(height: 8.h),
            _QuietNote(
              text:
                  '${plan.learningSessionsCount} جلسة حفظ موزعة على '
                  '${plan.targetLearningDays} يوم، والتقويم الفعلي '
                  '${plan.effectiveCalendarDays} يوم.',
            ),
          ],
          if (plan.intensityWarningText.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            _QuietNote(text: plan.intensityWarningText),
          ],
          SizedBox(height: 10.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _CompactMetric(
                  title: 'المدة',
                  value: _cleanDuration,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _CompactMetric(
                  title: 'الوضع',
                  value: _cleanLoad,
                  icon: Icons.speed_rounded,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _CompactMetric(
                  title: 'المراجعة',
                  value: _reviewLabel,
                  icon: Icons.repeat_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (_hasNewMemorization)
            _PlanLine(
              icon: Icons.menu_book_rounded,
              title: 'الحفظ',
              text: plan.dailyNewText,
            ),
          if (_hasNewMemorization && _hasReview) SizedBox(height: 7.h),
          if (_hasReview)
            _PlanLine(
              icon: Icons.repeat_rounded,
              title: 'المراجعة',
              text: plan.dailyBaseReviewText,
            ),
          if ((_hasNewMemorization || _hasReview) && _hasTests)
            SizedBox(height: 7.h),
          if (_hasTests)
            _PlanLine(
              icon: Icons.fact_check_rounded,
              title: 'الاختبارات',
              text: plan.selfTestText,
            ),
          SizedBox(height: 10.h),
          _QuietNote(text: _closingHint),
        ],
      ),
    );
  }

  String get _closingHint {
    if (_hasTests && _hasExtraDays) {
      return 'المدة تزيد قليلًا بسبب أيام الاختبار والمراجعة. لو تحب رحلة أقصر، يمكنك اختيار حفظ بدون مراجعة أو إيقاف الاختبارات الأسبوعية والشهرية.';
    }

    if (_hasTests) {
      return 'الاختبارات الأسبوعية والشهرية اختيارية، أما اختبار الختام فثابت في نهاية الرحلة.';
    }

    if (_hasReview) {
      return 'المراجعة تتوزع بهدوء حسب تقدمك.';
    }

    return 'ابدأ بخطوة صغيرة وثابتة كل يوم.';
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 43.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.34),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10.5.sp, color: theme.colorScheme.primary),
              SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.surface.withOpacity(0.42),
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface.withOpacity(0.72),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.050),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.07)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 13.5.sp),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.surface.withOpacity(0.63),
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.surface.withOpacity(0.55),
          height: 1.45,
        ),
      ),
    );
  }
}
