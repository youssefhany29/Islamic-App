import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class CurrentMemorizationPlanCard extends StatefulWidget {
  const CurrentMemorizationPlanCard({
    super.key,
    this.onPlanStopped,
  });

  final VoidCallback? onPlanStopped;

  @override
  State<CurrentMemorizationPlanCard> createState() =>
      _CurrentMemorizationPlanCardState();
}

class _CurrentMemorizationPlanCardState
    extends State<CurrentMemorizationPlanCard> {
  Future<MemorizationActivePlanModel?>? planFuture;

  @override
  void initState() {
    super.initState();
    planFuture = MemorizationPlanStorage.getActivePlan();
  }

  Future<void> _stopPlan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: theme.colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          title: Text(
            'إيقاف الخطة الحالية؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface
),
          ),
          content: Text(
            'سيتم إيقاف الخطة الحالية مع الاحتفاظ بتقدمك ونتائج جلساتك.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
color: theme.colorScheme.surface.withOpacity(0.70),
              height: 1.5
),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.surface.withOpacity(0.65),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'إيقاف',
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await MemorizationPlanStorage.stopActivePlan();

    if (!mounted) return;

    setState(() {
      planFuture = MemorizationPlanStorage.getActivePlan();
    });

    widget.onPlanStopped?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MemorizationActivePlanModel?>(
      future: planFuture,
      builder: (context, snapshot) {
        final plan = snapshot.data;

        if (plan == null) {
          return const SizedBox.shrink();
        }

        return _CurrentPlanContent(
          plan: plan,
          onStopTap: () => _stopPlan(context),
        );
      },
    );
  }
}

class _CurrentPlanContent extends StatelessWidget {
  const _CurrentPlanContent({
    required this.plan,
    required this.onStopTap,
  });

  final MemorizationActivePlanModel plan;
  final VoidCallback onStopTap;

  String get _durationLabel {
    final text = plan.durationText.trim();
    if (text.isEmpty) return 'غير محددة';

    final normalized = text
        .replaceAll('لمدة', '')
        .replaceAll('المدة المتوقعة:', '')
        .replaceAll('المدة:', '')
        .replaceAll('تقريبًا', '')
        .replaceAll('تقريبا', '')
        .replaceAll('حوالي', '')
        .trim();

    final numberWithUnit = RegExp(
      r'([0-9٠-٩]+)\s*(يوم|أيام|اسبوع|أسبوع|أسابيع|شهر|شهور|أشهر)',
    ).firstMatch(normalized);

    if (numberWithUnit != null) {
      return numberWithUnit.group(0)?.trim() ?? normalized;
    }

    if (normalized.contains('شهرين')) return 'شهرين';
    if (normalized.contains('شهر')) return 'شهر';
    if (normalized.contains('أسبوعين')) return 'أسبوعين';
    if (normalized.contains('اسبوعين')) return 'أسبوعين';

    final beforeExtraText = normalized
        .split('مع ')
        .first
        .split('بعد ')
        .first
        .split('شاملة')
        .first
        .trim();

    return beforeExtraText.isEmpty ? normalized : beforeExtraText;
  }

  String get _loadLabel {
    final text = plan.loadText.trim();

    if (text.isEmpty) return 'مريح';

    if (text.contains('مريح')) return 'مريح';
    if (text.contains('متوسط')) return 'متوسط';
    if (text.contains('قوي')) return 'قوي';
    if (text.contains('خفيف')) return 'خفيف';

    if (text.length > 12) return 'مناسب';

    return text;
  }

  String get _scopeLabel {
    final text = plan.scopeTitle.trim();
    return text.isEmpty ? 'نطاق الخطة' : text;
  }

  String get _dailyNewLine {
    final text = plan.dailyNewText.trim();

    if (text.isEmpty || text == 'لا يوجد حفظ جديد') {
      return 'لا يوجد حفظ جديد في هذه الخطة.';
    }

    return text;
  }

  String get _dailyReviewLine {
    final text = plan.dailyBaseReviewText.trim();

    if (text.isEmpty || text == 'لا يوجد مراجعة الآن') {
      return 'المراجعة خفيفة حسب تقدمك في الرحلة.';
    }

    return text;
  }

  bool get _hasReviewInfo {
    final text = plan.dailyBaseReviewText.trim();
    return text.isNotEmpty && text != 'لا يوجد مراجعة الآن';
  }

  String get _reviewChipLabel {
    return _hasReviewInfo ? 'مراجعة' : 'خفيفة';
  }

  bool get _hasSelfTestInfo {
    return plan.selfTestText.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.track_changes_rounded,
                  color: theme.colorScheme.primary,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            'الخطة الحالية',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary
),
                          ),
                        ),
                        const _StatusPill(text: 'نشطة'),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      plan.planName,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        height: 1.25
),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _ScopeLine(text: _scopeLabel),
          SizedBox(height: 8.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _MiniPlanMetricCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'المدة',
                  value: _durationLabel,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MiniPlanMetricCard(
                  icon: Icons.speed_rounded,
                  title: 'الوضع',
                  value: _loadLabel,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _MiniPlanMetricCard(
                  icon: Icons.repeat_rounded,
                  title: 'المراجعة',
                  value: _reviewChipLabel,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _CompactPlanDetailBox(
            title: 'الحفظ',
            text: _dailyNewLine,
            icon: Icons.menu_book_rounded,
          ),
          SizedBox(height: 7.h),
          _CompactPlanDetailBox(
            title: 'المراجعة',
            text: _dailyReviewLine,
            icon: Icons.repeat_rounded,
          ),
          if (_hasSelfTestInfo) ...[
            SizedBox(height: 7.h),
            _CompactPlanDetailBox(
              title: 'الاختبارات',
              text: plan.selfTestText.trim(),
              icon: Icons.fact_check_rounded,
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  'إيقاف الخطة لا يحذف تقدمك.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                    color: theme.colorScheme.surface.withOpacity(0.46),
                    height: 1.25
),
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: theme.colorScheme.primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(30.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30.r),
                  onTap: onStopTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    child: Text(
                      'إيقاف',
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary
),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.10),
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

class _ScopeLine extends StatelessWidget {
  const _ScopeLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: theme.colorScheme.primary,
            size: 15.5.sp,
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                color: theme.colorScheme.surface.withOpacity(0.66),
                height: 1.32
),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlanMetricCard extends StatelessWidget {
  const _MiniPlanMetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 43.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.34),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 10.5.sp,
                color: theme.colorScheme.primary,
              ),
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
                    height: 1
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
              height: 1
),
          ),
        ],
      ),
    );
  }
}

class _CompactPlanDetailBox extends StatelessWidget {
  const _CompactPlanDetailBox({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.050),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.07),
        ),
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
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 13.5.sp,
            ),
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
                    height: 1.15
),
                ),
                SizedBox(height: 3.h),
                Text(
                  text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                    color: theme.colorScheme.surface.withOpacity(0.63),
                    height: 1.38
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