import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';

class CurrentPlanArchivedPlansCard extends StatefulWidget {
  const CurrentPlanArchivedPlansCard({
    super.key,
    required this.onPlanReactivated,
    this.topSpacing = 0,
  });

  final VoidCallback onPlanReactivated;
  final double topSpacing;

  @override
  State<CurrentPlanArchivedPlansCard> createState() =>
      _CurrentPlanArchivedPlansCardState();
}

class _CurrentPlanArchivedPlansCardState
    extends State<CurrentPlanArchivedPlansCard> {
  late Future<List<MemorizationActivePlanModel>> plansFuture;

  @override
  void initState() {
    super.initState();
    plansFuture = MemorizationPlanStorage.getArchivedPlans();
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {
      plansFuture = MemorizationPlanStorage.getArchivedPlans();
    });
  }

  Future<void> _reactivatePlan(MemorizationActivePlanModel plan) async {
    AppHaptics.tap(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          title: Text(
            'استرجاع الخطة؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(context).copyWith(
              color: colors.surface,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'سيتم جعل "${plan.planName}" هي الخطة الحالية، وأي خطة نشطة أخرى ستتوقف بدون حذف تقدمها.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              color: colors.surface.withOpacity(0.68),
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.surface.withOpacity(0.58),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'استرجاع',
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.primary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await MemorizationPlanStorage.reactivatePlan(plan.id);
    _refresh();
    widget.onPlanReactivated();
  }

  Future<void> _deletePlan(MemorizationActivePlanModel plan) async {
    AppHaptics.tap(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          title: Text(
            'حذف الخطة نهائيًا؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(context).copyWith(
              color: colors.surface,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'سيتم حذف "${plan.planName}" من قائمة الخطط المتوقفة. لا تستخدم هذا إلا لو أنت متأكد.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              color: colors.surface.withOpacity(0.68),
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.surface.withOpacity(0.58),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'حذف',
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.redAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await MemorizationPlanStorage.deletePlan(plan.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MemorizationActivePlanModel>>(
      future: plansFuture,
      builder: (context, snapshot) {
        final plans = snapshot.data ?? const <MemorizationActivePlanModel>[];
        if (plans.isEmpty) return const SizedBox.shrink();

        final content = _ArchivedPlansContent(
          plans: plans,
          onReactivatePlan: _reactivatePlan,
          onDeletePlan: _deletePlan,
        );

        if (widget.topSpacing <= 0) return content;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: widget.topSpacing),
            content,
          ],
        );
      },
    );
  }
}

class _ArchivedPlansContent extends StatelessWidget {
  const _ArchivedPlansContent({
    required this.plans,
    required this.onReactivatePlan,
    required this.onDeletePlan,
  });

  final List<MemorizationActivePlanModel> plans;
  final ValueChanged<MemorizationActivePlanModel> onReactivatePlan;
  final ValueChanged<MemorizationActivePlanModel> onDeletePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final cardColor = isDark ? colors.secondary : Colors.white;
    final innerCardColor = isDark
        ? colors.surface.withOpacity(0.055)
        : const Color(0xFFFAFCFE);
    final borderColor = isDark
        ? colors.outline.withOpacity(0.12)
        : const Color(0xFFE7EDF5);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 15.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pause_circle_outline_rounded,
                  color: colors.primary,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الخطط المتوقفة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        color: textColor,
                        fontSize: 12.2.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '${plans.length} خطة محفوظة يمكنك استرجاعها',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor.withOpacity(0.56),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 228.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  for (int index = 0; index < plans.length; index++) ...[
                    _ArchivedPlanTile(
                      plan: plans[index],
                      textColor: textColor,
                      primaryColor: colors.primary,
                      cardColor: innerCardColor,
                      borderColor: borderColor,
                      onReactivateTap: () => onReactivatePlan(plans[index]),
                      onDeleteTap: () => onDeletePlan(plans[index]),
                    ),
                    if (index != plans.length - 1) SizedBox(height: 9.h),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedPlanTile extends StatelessWidget {
  const _ArchivedPlanTile({
    required this.plan,
    required this.textColor,
    required this.primaryColor,
    required this.cardColor,
    required this.borderColor,
    required this.onReactivateTap,
    required this.onDeleteTap,
  });

  final MemorizationActivePlanModel plan;
  final Color textColor;
  final Color primaryColor;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onReactivateTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: 0.8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: primaryColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.planName,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      _planSubtitle(plan),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: textColor.withOpacity(0.54),
                        fontSize: 8.3.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _ArchivedPlanActionButton(
                text: 'استرجاع',
                icon: Icons.restore_rounded,
                color: primaryColor,
                onTap: onReactivateTap,
              ),
              SizedBox(width: 8.w),
              _ArchivedPlanActionButton(
                text: 'حذف',
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                onTap: onDeleteTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _planSubtitle(MemorizationActivePlanModel plan) {
    final scope = plan.scopeTitle.trim().isEmpty
        ? 'نطاق الخطة'
        : plan.scopeTitle;
    final days = plan.totalDays <= 0
        ? 'مدة غير محددة'
        : '${plan.totalDays} يوم';
    return '$scope • $days';
  }
}

class _ArchivedPlanActionButton extends StatelessWidget {
  const _ArchivedPlanActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: color, size: 12.sp),
              SizedBox(width: 4.w),
              Text(
                text,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  color: color,
                  fontSize: 8.8.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
