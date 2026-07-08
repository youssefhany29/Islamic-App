import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import 'package:islamic_app/features/prayer/data/services/prayer_based_azkar_period_service.dart';
import 'package:islamic_app/features/azkar/presentation/pages/evening_zekr.dart';
import 'package:islamic_app/features/azkar/presentation/pages/morning_zekr.dart';

class ZekrSmartStartCard extends StatefulWidget {
  const ZekrSmartStartCard({super.key});

  @override
  State<ZekrSmartStartCard> createState() => _ZekrSmartStartCardState();
}

class _ZekrSmartStartCardState extends State<ZekrSmartStartCard> {
  late AzkarPrayerPeriod _period;

  bool get isMorning => _period.isMorning;

  @override
  void initState() {
    super.initState();
    _period = _fallbackPeriod();
    _loadCurrentZekrPeriod();
  }

  AzkarPrayerPeriod _fallbackPeriod() {
    final now = DateTime.now();

    if (now.hour >= 5 && now.hour < 15) {
      return AzkarPrayerPeriod.morning;
    }

    return AzkarPrayerPeriod.evening;
  }

  Future<void> _loadCurrentZekrPeriod() async {
    final period = await const PrayerBasedAzkarPeriodService().getCurrentPeriod();

    if (!mounted) return;
    if (_period == period) return;

    setState(() {
      _period = period;
    });
  }

  void _openCurrentZekrPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isMorning ? MorningZekr() : EveningZekr(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;
    final colors = Theme.of(context).colorScheme;

    final String title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final String subtitle =
    isMorning ? 'ابدأ يومك بذكر الله' : 'اختم يومك بطمأنينة';

    final double horizontalPadding = isLargeScreen ? 18 : 14.w;
    final double verticalPadding = isLargeScreen ? 12 : 8.h;
    final double iconBoxSize = isLargeScreen ? 44 : 34.w;
    final double titleSize = isLargeScreen ? 16 : 14.sp;
    final double subtitleSize = isLargeScreen ? 12.5 : 8.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: _openCurrentZekrPage,
        child: SizedBox(
          width: AppLayoutConstants.mainCardWidth,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: horizontalPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                isLargeScreen ? 20 : 16.r,
              ),
              color: colors.secondary,
              border: Border.all(
                color: colors.outline.withOpacity(isLargeScreen ? 0.65 : 1),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withOpacity(0.12),
                  ),
                  child: Icon(
                    isMorning
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                    color: colors.primary,
                    size: isLargeScreen ? 23 : 18.sp,
                  ),
                ),

                SizedBox(width: isLargeScreen ? 14 : 10.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: colors.surface,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: isLargeScreen ? 3 : 2.h),

                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            color: colors.surface.withOpacity(0.70),
                            height: 1.25,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isLargeScreen ? 12 : 8.w),

                Transform.rotate(
                  angle: math.pi,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colors.surface.withOpacity(0.78),
                    size: isLargeScreen ? 18 : 14.sp,
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