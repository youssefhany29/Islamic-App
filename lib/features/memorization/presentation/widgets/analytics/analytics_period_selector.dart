import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/analytics_ui.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/analytics/memorization_analytics_data.dart';

class AnalyticsPeriodSelector extends StatelessWidget {
  const AnalyticsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  final MemorizationAnalyticsPeriod selectedPeriod;
  final ValueChanged<MemorizationAnalyticsPeriod> onChanged;

  Future<void> _openMenu(BuildContext context) async {
    final renderBox = context.findRenderObject();
    final overlayBox = Navigator.of(context).overlay?.context.findRenderObject();

    if (renderBox is! RenderBox || overlayBox is! RenderBox) return;

    final Offset buttonOffset = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size buttonSize = renderBox.size;
    final Size overlaySize = overlayBox.size;

    final double menuWidth = math.max(buttonSize.width, 155.w);
    final double menuLeft = (buttonOffset.dx + (buttonSize.width - menuWidth) / 2)
        .clamp(10.w, overlaySize.width - menuWidth - 10.w)
        .toDouble();
    final double menuTop = buttonOffset.dy + buttonSize.height + 7.h;

    final selected = await showMenu<MemorizationAnalyticsPeriod>(
      context: context,
      color: Theme.of(context).colorScheme.primary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
      ),
      position: RelativeRect.fromLTRB(
        menuLeft,
        menuTop,
        overlaySize.width - menuLeft - menuWidth,
        overlaySize.height - menuTop,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      items: MemorizationAnalyticsPeriod.values.map((period) {
        final bool selected = period == selectedPeriod;

        return PopupMenuItem<MemorizationAnalyticsPeriod>(
          value: period,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: Colors.white.withOpacity(selected ? 0.96 : 0.46),
                  size: 17.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    period.label,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: Colors.white.withOpacity(selected ? 0.96 : 0.70),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Builder(
          builder: (buttonContext) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openMenu(buttonContext),
              child: Container(
                height: 30.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.075),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white.withOpacity(0.88),
                      size: 17.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      selectedPeriod.label,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white,
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.80),
                      size: 18.sp,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
