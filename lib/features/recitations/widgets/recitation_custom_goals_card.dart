import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/recitation_custom_goal_model.dart';
import '../services/recitation_custom_goals_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class RecitationCustomGoalsCard extends StatelessWidget {
  final List<RecitationCustomGoalProgress> goals;
  final VoidCallback onAddGoal;
  final Future<void> Function(String id) onDeleteGoal;

  const RecitationCustomGoalsCard({
    super.key,
    required this.goals,
    required this.onAddGoal,
    required this.onDeleteGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SectionHeader(
            title: 'أهدافي الشخصية',
            icon: Icons.flag_rounded,
            onAddGoal: onAddGoal,
          ),
          SizedBox(height: 10.h),
          if (goals.isEmpty)
            _EmptyGoalsCard(onAddGoal: onAddGoal)
          else
            ...goals.map(
                  (goalProgress) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _CustomGoalTile(
                  goalProgress: goalProgress,
                  onDelete: () => onDeleteGoal(goalProgress.goal.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onAddGoal;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.8.w,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            color: const Color(0xff21C58E),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                color: Colors.white
),
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                AppHaptics.tap(context);
                onAddGoal();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 5.h,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'إضافة',
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                        color: Colors.white
),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalsCard extends StatelessWidget {
  final VoidCallback onAddGoal;

  const _EmptyGoalsCard({
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xff171B26),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          AppHaptics.tap(context);
          onAddGoal();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.8.w,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'أضف هدفك الشخصي وابدأ متابعة تقدمك مع القرآن',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.82),
                    height: 1.35
),
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                Icons.add_task_rounded,
                color: const Color(0xff21C58E),
                size: 19.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomGoalTile extends StatelessWidget {
  final RecitationCustomGoalProgress goalProgress;
  final VoidCallback onDelete;

  const _CustomGoalTile({
    required this.goalProgress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final goal = goalProgress.goal;
    final info = goal.type.info;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xff171B26),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: goalProgress.completed
              ? const Color(0xff21C58E)
              : Colors.white.withOpacity(0.12),
          width: 0.8.w,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: goalProgress.completed
                ? const Color(0xff21C58E)
                : Colors.white.withOpacity(0.12),
            child: Icon(
              goalProgress.completed ? Icons.check_rounded : info.icon,
              color: Colors.white,
              size: 18.sp,
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
                        goal.title,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                          color: Colors.white
),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () {
                        AppHaptics.tap(context);
                        onDelete();
                      },
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white.withOpacity(0.55),
                        size: 17.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  goalProgress.completed
                      ? 'مكتمل، ما شاء الله'
                      : goalProgress.progressText,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.62)
),
                ),
                SizedBox(height: 7.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: goalProgress.progress,
                    minHeight: 4.h,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goalProgress.completed
                          ? const Color(0xff21C58E)
                          : const Color(0xffffb300),
                    ),
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