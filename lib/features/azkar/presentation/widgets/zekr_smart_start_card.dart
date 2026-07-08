import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/prayer/data/services/prayer_based_azkar_period_service.dart';
import 'package:islamic_app/features/azkar/data/datasources/zekr_local_data.dart';
import 'package:islamic_app/features/azkar/data/models/zekr_category_model.dart';
import 'package:islamic_app/features/azkar/presentation/pages/zekr_reading_page.dart';

class ZekrSmartStartCard extends StatefulWidget {
  const ZekrSmartStartCard({super.key});

  @override
  State<ZekrSmartStartCard> createState() => _ZekrSmartStartCardState();
}

class _ZekrSmartStartCardState extends State<ZekrSmartStartCard> {
  late AzkarPrayerPeriod _period;

  bool get _isMorning => _period.isMorning;

  @override
  void initState() {
    super.initState();

    // بداية فورية عشان الكارت مايفضلش يعمل Loading.
    _period = _fallbackPeriod();

    // تحديث هادئ حسب مواقيت الفجر والعصر المحفوظة.
    _loadCurrentPeriod();
  }

  AzkarPrayerPeriod _fallbackPeriod() {
    final DateTime now = DateTime.now();

    if (now.hour >= 5 && now.hour < 15) {
      return AzkarPrayerPeriod.morning;
    }

    return AzkarPrayerPeriod.evening;
  }

  Future<void> _loadCurrentPeriod() async {
    final AzkarPrayerPeriod period = await const PrayerBasedAzkarPeriodService()
        .getCurrentPeriod();

    if (!mounted) return;
    if (_period == period) return;

    setState(() {
      _period = period;
    });
  }

  ZekrCategoryModel _currentCategory() {
    return _isMorning
        ? ZekrLocalData.getCategoryById(ZekrLocalData.morningId)
        : ZekrLocalData.getCategoryById(ZekrLocalData.eveningId);
  }

  void _openCurrentZekr(BuildContext context) {
    final ZekrCategoryModel category = _currentCategory();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ZekrReadingPage(category: category);
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _isMorning
        ? 'حان وقت أذكار الصباح'
        : 'حان وقت أذكار المساء';

    final String subtitle = _isMorning
        ? 'من الفجر إلى قبل العصر'
        : 'من العصر إلى قبل الفجر';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCurrentZekr(context),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  _isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: Theme.of(context).colorScheme.primary,
                  size: 23.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.surface,
                size: 15.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
