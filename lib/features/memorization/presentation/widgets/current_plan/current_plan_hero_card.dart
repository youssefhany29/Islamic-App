import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/current_plan/current_plan_hero_data.dart';

class CurrentPlanHeroCard extends StatelessWidget {
  const CurrentPlanHeroCard({super.key, required this.data});

  final CurrentPlanHeroData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);
    final mutedTextColor = textColor.withOpacity(0.58);
    final translucentBorder = Colors.white.withOpacity(isDark ? 0.12 : 0.24);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.055 : 0.12),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: translucentBorder, width: 0.9.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(
                planTitle: data.scopeTitle,
                rangeLabel: data.rangeLabel,
              ),
              SizedBox(height: 11.h),
              _PlanInfoCard(
                textColor: textColor,
                mutedTextColor: mutedTextColor,
                primaryColor: colors.primary,
                isDark: isDark,
                rows: [
                  _PlanInfoRowData(
                    rightTitle: 'النطاق الحالي',
                    rightValue: data.scopeTitle,
                    leftTitle: 'التقدم من المخطط',
                    leftValue: data.progressLabel,
                  ),
                  _PlanInfoRowData(
                    rightTitle: 'حجم الخطة',
                    rightValue: data.pagesLabel,
                    leftTitle: 'الاختبارات القادمة',
                    leftValue: data.testsLabel,
                  ),
                  _PlanInfoRowData(
                    rightTitle: 'اليوم الحالي',
                    rightValue: data.currentPlanDayLabel,
                    leftTitle: 'أيام الحفظ',
                    leftValue: data.currentLessonLabel,
                  ),
                  _PlanInfoRowData(
                    rightTitle: 'مدة الخطة',
                    rightValue: data.durationLabel,
                    rightMaxLines: 3,
                    leftTitle: 'الصفحات المتبقية',
                    leftValue: data.remainingPagesLabel,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _CurrentProgressCard(
                data: data,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
                primaryColor: colors.primary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrentPlanEmptyHeroCard extends StatelessWidget {
  const CurrentPlanEmptyHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? colors.surface : const Color(0xFF18385F);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.055 : 0.12),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.12 : 0.24),
              width: 0.9.w,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 18.h),
            decoration: BoxDecoration(
              color: isDark ? colors.secondary : Colors.white,
              borderRadius: BorderRadius.circular(19.r),
              border: Border.all(
                color: isDark
                    ? colors.outline.withOpacity(0.12)
                    : const Color(0xFFE8EEF4),
                width: 0.8.w,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: colors.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'لا توجد خطة حالية',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context).copyWith(
                    color: textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'ابدأ خطة جديدة وسيظهر ملخصها هنا.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    color: textColor.withOpacity(0.56),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.planTitle, required this.rangeLabel});

  final String planTitle;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                planTitle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                rangeLabel,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 8.8.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: const Color(0xFF244F7B),
            size: 18.sp,
          ),
        ),
      ],
    );
  }
}

class _PlanInfoCard extends StatelessWidget {
  const _PlanInfoCard({
    required this.textColor,
    required this.mutedTextColor,
    required this.primaryColor,
    required this.isDark,
    required this.rows,
  });

  final Color textColor;
  final Color mutedTextColor;
  final Color primaryColor;
  final bool isDark;
  final List<_PlanInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.12)
              : const Color(0xFFE7EDF5),
          width: 0.8.w,
        ),
      ),
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _PlanInfoRow(
              data: rows[index],
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              primaryColor: primaryColor,
            ),
            if (index != rows.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 7.h),
                child: Divider(
                  height: 1,
                  thickness: 0.7.h,
                  color: isDark
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.10)
                      : const Color(0xFFEAF0F7),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlanInfoRow extends StatelessWidget {
  const _PlanInfoRow({
    required this.data,
    required this.textColor,
    required this.mutedTextColor,
    required this.primaryColor,
  });

  final _PlanInfoRowData data;
  final Color textColor;
  final Color mutedTextColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _PlanInfoValue(
            title: data.rightTitle,
            value: data.rightValue,
            titleColor: mutedTextColor,
            valueColor: primaryColor,
            maxLines: data.rightMaxLines,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _PlanInfoValue(
            title: data.leftTitle,
            value: data.leftValue,
            titleColor: mutedTextColor,
            valueColor: textColor,
            maxLines: data.leftMaxLines,
          ),
        ),
      ],
    );
  }
}

class _PlanInfoValue extends StatelessWidget {
  const _PlanInfoValue({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
    this.maxLines = 1,
  });

  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: titleColor,
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          maxLines: maxLines,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: valueColor,
            fontSize: 9.2.sp,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _CurrentProgressCard extends StatelessWidget {
  const _CurrentProgressCard({
    required this.data,
    required this.textColor,
    required this.mutedTextColor,
    required this.primaryColor,
    required this.isDark,
  });

  final CurrentPlanHeroData data;
  final Color textColor;
  final Color mutedTextColor;
  final Color primaryColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 11.h),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.12)
              : const Color(0xFFE7EDF5),
          width: 0.8.w,
        ),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  'تقدم الخطة',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: textColor,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                data.remainingDaysLabel,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: primaryColor,
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _StageProgressLine(
            items: data.stageItems,
            progressPercent: data.progressPercent,
            activeColor: primaryColor,
            inactiveColor: mutedTextColor.withOpacity(0.20),
          ),
        ],
      ),
    );
  }
}

class _StageProgressLine extends StatelessWidget {
  const _StageProgressLine({
    required this.items,
    required this.progressPercent,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<CurrentPlanStageItem> items;
  final int progressPercent;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 12.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 4.w,
                right: 4.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: Container(
                    height: 2.h,
                    color: inactiveColor,
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: (progressPercent / 100)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 2.h,
                        color: activeColor.withOpacity(0.62),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final item in items)
                    _StageDot(
                      active: item.active,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in items)
              Text(
                item.title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                  color: item.active
                      ? activeColor
                      : inactiveColor.withOpacity(0.80),
                  fontSize: 7.6.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
  });

  final bool active;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: active ? activeColor : inactiveColor,
        shape: BoxShape.circle,
      ),
      child: active
          ? Center(
              child: Container(
                width: 4.w,
                height: 4.w,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _PlanInfoRowData {
  const _PlanInfoRowData({
    required this.rightTitle,
    required this.rightValue,
    required this.leftTitle,
    required this.leftValue,
    this.rightMaxLines = 3,
    this.leftMaxLines = 3,
  });

  final String rightTitle;
  final String rightValue;
  final String leftTitle;
  final String leftValue;
  final int rightMaxLines;
  final int leftMaxLines;
}
