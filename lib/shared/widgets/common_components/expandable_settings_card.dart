import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class ExpandableSettingsCard extends StatefulWidget {
  const ExpandableSettingsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ExpandableSettingsCard> createState() => _ExpandableSettingsCardState();
}

class _ExpandableSettingsCardState extends State<ExpandableSettingsCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    AppHaptics.tap(context);

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: _toggleExpanded,
              child: SizedBox(
                width: double.infinity,
                height: 66.h,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(left: 52.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w700,
                                  color: Colors.white
),
                              ),
                            ),

                            SizedBox(height: 5.h),

                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                widget.subtitle,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.78),
                                  height: 1.35
),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 42.w,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              color: const Color(0xff21C58E),
                              size: 23.sp,
                            ),

                            SizedBox(height: 4.h),

                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 25.sp,
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

            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: _isExpanded
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 16.h),
                    ...widget.children,
                  ],
                )
                    : const SizedBox(
                  width: double.infinity,
                  height: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}