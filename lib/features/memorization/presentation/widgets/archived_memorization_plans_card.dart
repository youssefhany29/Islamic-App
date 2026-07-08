import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class ArchivedMemorizationPlansCard extends StatefulWidget {
  const ArchivedMemorizationPlansCard({
    super.key,
    this.onPlanReactivated,
  });

  final VoidCallback? onPlanReactivated;

  @override
  State<ArchivedMemorizationPlansCard> createState() =>
      _ArchivedMemorizationPlansCardState();
}

class _ArchivedMemorizationPlansCardState
    extends State<ArchivedMemorizationPlansCard> {
  Future<List<MemorizationActivePlanModel>>? archivedPlansFuture;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    archivedPlansFuture = MemorizationPlanStorage.getArchivedPlans();
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {
      archivedPlansFuture = MemorizationPlanStorage.getArchivedPlans();
    });
  }

  Future<void> _reactivatePlan(
      BuildContext context,
      MemorizationActivePlanModel plan,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: theme.colorScheme.background,
          title: Text(
            'استرجاع هذه الخطة؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface
),
          ),
          content: Text(
            'سيتم جعل "${plan.planName}" هي الخطة النشطة الآن، وأي خطة نشطة أخرى سيتم إيقافها بدون مسح تقدمها.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
color: theme.colorScheme.surface.withOpacity(0.72),
              height: 1.55
),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'استرجاع',
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

    if (confirmed != true) return;

    await MemorizationPlanStorage.reactivatePlan(plan.id);
    await _refresh();

    widget.onPlanReactivated?.call();
  }

  Future<void> _deletePlan(
      BuildContext context,
      MemorizationActivePlanModel plan,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: theme.colorScheme.background,
          title: Text(
            'حذف الخطة نهائيًا؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface
),
          ),
          content: Text(
            'سيتم حذف "${plan.planName}" من قائمة الخطط المتوقفة. لا تستخدم هذا إلا لو أنت متأكد.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
color: theme.colorScheme.surface.withOpacity(0.72),
              height: 1.55
),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف',
                style: TextStyle(
                  color: Colors.redAccent,
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
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MemorizationActivePlanModel>>(
      future: archivedPlansFuture,
      builder: (context, snapshot) {
        final plans = snapshot.data ?? [];

        if (plans.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ArchivedPlansContent(
          plans: plans,
          isExpanded: isExpanded,
          onToggleExpanded: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          onReactivatePlan: (plan) => _reactivatePlan(context, plan),
          onDeletePlan: (plan) => _deletePlan(context, plan),
        );
      },
    );
  }
}

class _ArchivedPlansContent extends StatelessWidget {
  const _ArchivedPlansContent({
    required this.plans,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onReactivatePlan,
    required this.onDeletePlan,
  });

  final List<MemorizationActivePlanModel> plans;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<MemorizationActivePlanModel> onReactivatePlan;
  final ValueChanged<MemorizationActivePlanModel> onDeletePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visiblePlans = isExpanded ? plans : plans.take(1).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: onToggleExpanded,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: theme.colorScheme.primary,
                        size: 20.sp,
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
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                              color: theme.colorScheme.surface
),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '${plans.length} خطة محفوظة. اضغط للفتح أو الإغلاق.',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                              color:
                              theme.colorScheme.surface.withOpacity(0.58),
                              height: 1.4
),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.surface.withOpacity(0.55),
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: isExpanded
                ? Column(
              children: [
                SizedBox(height: 12.h),
                ...visiblePlans.map(
                      (plan) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _ArchivedPlanTile(
                      plan: plan,
                      onReactivateTap: () => onReactivatePlan(plan),
                      onDeleteTap: () => onDeletePlan(plan),
                    ),
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ArchivedPlanTile extends StatelessWidget {
  const _ArchivedPlanTile({
    required this.plan,
    required this.onReactivateTap,
    required this.onDeleteTap,
  });

  final MemorizationActivePlanModel plan;
  final VoidCallback onReactivateTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.36),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.10),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pause_circle_filled_rounded,
            color: theme.colorScheme.primary.withOpacity(0.85),
            size: 21.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                SizedBox(height: 4.h),
                Text(
                  '${plan.scopeTitle} • ${plan.durationText} • ${plan.loadText}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                    color: theme.colorScheme.surface.withOpacity(0.55),
                    height: 1.35
),
                ),
                SizedBox(height: 9.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _TinyActionButton(
                      text: 'استرجاع',
                      icon: Icons.play_arrow_rounded,
                      onTap: onReactivateTap,
                    ),
                    SizedBox(width: 7.w),
                    _TinyActionButton(
                      text: 'حذف',
                      icon: Icons.delete_outline_rounded,
                      isDanger: true,
                      onTap: onDeleteTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDanger ? Colors.redAccent : theme.colorScheme.primary;

    return Material(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(30.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(30.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                  color: color,
                  height: 1
),
              ),
              SizedBox(width: 3.w),
              Icon(
                icon,
                color: color,
                size: 13.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
