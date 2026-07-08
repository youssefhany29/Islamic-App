import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsRangeGroupsBlock extends StatefulWidget {
  const AnalyticsRangeGroupsBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.chipColor,
    required this.chipTextColor,
    required this.emptyText,
    required this.groups,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color chipColor;
  final Color chipTextColor;
  final String emptyText;
  final List<AnalyticsRangeGroup> groups;

  @override
  State<AnalyticsRangeGroupsBlock> createState() => _AnalyticsRangeGroupsBlockState();
}

class _AnalyticsRangeGroupsBlockState extends State<AnalyticsRangeGroupsBlock> {
  String? expandedTitle;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.groups.isEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: AnalyticsDecorations.innerCard(context, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                widget.icon,
                color: widget.iconColor,
                size: 17.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AnalyticsThemeColors.textPrimary(context),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          if (isEmpty)
            _EmptyRangeChip(text: widget.emptyText)
          else ...[
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                runAlignment: WrapAlignment.end,
                textDirection: TextDirection.rtl,
                spacing: 8.w,
                runSpacing: 8.h,
                children: widget.groups.take(6).map((group) {
                  final bool isExpanded = expandedTitle == group.title;

                  return _RangeGroupChip(
                    group: group,
                    color: widget.chipColor,
                    textColor: widget.chipTextColor,
                    isExpanded: isExpanded,
                    onTap: () {
                      AppHaptics.tap(context);
                      setState(() {
                        expandedTitle = isExpanded ? null : group.title;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              child: _expandedGroup == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: ValueKey(_expandedGroup!.title),
                      padding: EdgeInsets.only(top: 11.h),
                      child: _ExpandedRangesPanel(
                        group: _expandedGroup!,
                        color: widget.iconColor,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  AnalyticsRangeGroup? get _expandedGroup {
    final title = expandedTitle;
    if (title == null) return null;

    for (final group in widget.groups) {
      if (group.title == title) return group;
    }

    return null;
  }
}

class _RangeGroupChip extends StatelessWidget {
  const _RangeGroupChip({
    required this.group,
    required this.color,
    required this.textColor,
    required this.isExpanded,
    required this.onTap,
  });

  final AnalyticsRangeGroup group;
  final Color color;
  final Color textColor;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(30.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(30.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                group.title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor,
                  fontSize: 8.9.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(width: 5.w),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textColor.withOpacity(0.85),
                  size: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedRangesPanel extends StatelessWidget {
  const _ExpandedRangesPanel({
    required this.group,
    required this.color,
  });

  final AnalyticsRangeGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ranges = group.ranges.isEmpty ? <String>[group.subtitle] : group.ranges;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      decoration: AnalyticsDecorations.miniCard(context, radius: 16.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 200.h),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ranges.map((range) {
              return Padding(
                padding: EdgeInsets.only(bottom: 7.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      margin: EdgeInsets.only(top: 4.h),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.70),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        range,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.caption(context).copyWith(
                          color: AnalyticsThemeColors.textSecondary(context, 0.66),
                          fontSize: 8.7.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _EmptyRangeChip extends StatelessWidget {
  const _EmptyRangeChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AnalyticsThemeColors.emptyChip(context),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            color: AnalyticsThemeColors.textSecondary(context, 0.46),
            fontSize: 8.9.sp,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
