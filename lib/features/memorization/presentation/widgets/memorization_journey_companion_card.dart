import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/features/memorization/data/services/memorization_journey_companion_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class MemorizationJourneyCompanionCard extends StatefulWidget {
  const MemorizationJourneyCompanionCard({
    super.key,
    required this.onPlanActivated,
  });

  final VoidCallback onPlanActivated;

  @override
  State<MemorizationJourneyCompanionCard> createState() =>
      _MemorizationJourneyCompanionCardState();
}

class _MemorizationJourneyCompanionCardState
    extends State<MemorizationJourneyCompanionCard> {
  final service = const MemorizationJourneyCompanionService();

  Future<MemorizationJourneyCompanionReport>? reportFuture;
  bool isActivatingPlan = false;

  @override
  void initState() {
    super.initState();
    reportFuture = service.buildReport();
  }

  Future<void> _refresh() async {
    setState(() {
      reportFuture = service.buildReport();
    });
  }

  Future<void> _activateQuickPlan(
    MemorizationJourneyCompanionReport report,
  ) async {
    final quickPlan = report.quickPlan;
    final activePlan = report.activePlan;

    if (quickPlan == null || activePlan == null || isActivatingPlan) return;

    AppHaptics.tap(context);

    final confirmed = await _confirmQuickPlan(report);
    if (confirmed != true) return;

    if (!mounted) return;

    setState(() => isActivatingPlan = true);

    try {
      await service.activateQuickStabilizationPlan(
        quickPlan: quickPlan,
        sourcePlan: activePlan,
      );

      if (!mounted) return;

      _showSnackBar('تم وضع رحلة التثبيت في التقويم بهدوء 🌿');

      widget.onPlanActivated();
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('حدث خطأ أثناء تجهيز رحلة التثبيت. جرّب مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() => isActivatingPlan = false);
      }
    }
  }

  Future<bool?> _confirmQuickPlan(MemorizationJourneyCompanionReport report) {
    final theme = Theme.of(context);
    final quickPlan = report.quickPlan!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.background,
          title: Text(
            'نبدأ رحلة تثبيت قصيرة؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface,
            ),
          ),
          content: Text(
            'هنجهز لك رحلة هادئة لمدة ${quickPlan.days} أيام، بدون حفظ جديد، وتركّز على المواضع التي احتاجت تثبيت.\n\nلو وافقت، هتتحط كخطة نشطة وتظهر في التقويم.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              height: 1.55,
              color: theme.colorScheme.surface.withOpacity(0.72),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ليس الآن'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'ابدأ الرحلة',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.background,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MemorizationJourneyCompanionReport>(
      future: reportFuture,
      builder: (context, snapshot) {
        final report = snapshot.data;

        if (report == null) {
          return const SizedBox.shrink();
        }

        return _CompanionCardBody(
          report: report,
          isActivatingPlan: isActivatingPlan,
          onActivateQuickPlan: () => _activateQuickPlan(report),
        );
      },
    );
  }
}

class _CompanionCardBody extends StatelessWidget {
  const _CompanionCardBody({
    required this.report,
    required this.isActivatingPlan,
    required this.onActivateQuickPlan,
  });

  final MemorizationJourneyCompanionReport report;
  final bool isActivatingPlan;
  final VoidCallback onActivateQuickPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quickPlan = report.quickPlan;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
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
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: theme.colorScheme.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      report.title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      report.message,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.58),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _ScoreBox(
                  title: 'ثبات الحفظ',
                  value: '${report.stabilityPercent}%',
                  icon: Icons.psychology_alt_rounded,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: _ScoreBox(
                  title: 'الالتزام',
                  value: '${report.commitmentPercent}%',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
          if (report.focusPoints.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _FocusPoints(points: report.focusPoints),
          ],
          if (quickPlan != null) ...[
            SizedBox(height: 12.h),
            _QuickPlanBox(
              quickPlan: quickPlan,
              isActivatingPlan: isActivatingPlan,
              onActivateQuickPlan: onActivateQuickPlan,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
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
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 18.sp),
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
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.surface.withOpacity(0.58),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
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

class _FocusPoints extends StatelessWidget {
  const _FocusPoints({required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'اهتم في الفترة الجاية بـ:',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 7.h),
          ...points.map(
            (point) => Padding(
              padding: EdgeInsets.only(bottom: 5.h),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      point,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.surface.withOpacity(0.68),
                        height: 1.45,
                      ),
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

class _QuickPlanBox extends StatelessWidget {
  const _QuickPlanBox({
    required this.quickPlan,
    required this.isActivatingPlan,
    required this.onActivateQuickPlan,
  });

  final MemorizationQuickStabilizationPlan quickPlan;
  final bool isActivatingPlan;
  final VoidCallback onActivateQuickPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.36),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary,
                size: 19.sp,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  quickPlan.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            '${quickPlan.days} أيام • اختبارات تلقائية حسب تقدمك',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.surface.withOpacity(0.62),
              height: 1.45,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(17.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(17.r),
                onTap: isActivatingPlan ? null : onActivateQuickPlan,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      if (isActivatingPlan)
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      SizedBox(width: 7.w),
                      Text(
                        isActivatingPlan
                            ? 'جاري التجهيز...'
                            : 'ابدأ رحلة التثبيت',
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
