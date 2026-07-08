import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'phone_quran_reading_summary_info.dart';
import 'quran_nearest_khatma_progress_card.dart';
import 'quran_reading_stat_box.dart';
import 'quran_reading_summary_header.dart';

class PhoneQuranReadingSummarySection extends StatelessWidget {
  const PhoneQuranReadingSummarySection({
    super.key,
    required this.info,
  });

  final PhoneQuranReadingSummaryInfo info;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: isLargeScreen ? double.infinity : AppLayoutConstants.mainCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QuranReadingSummaryHeader(),
            SizedBox(height: 12.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: QuranReadingStatBox(
                    title: 'الختمات\nالحالية',
                    value: info.activeKhatmas.toString(),
                    icon: Icons.refresh_rounded,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: QuranReadingStatBox(
                    title: 'السلسلة\nالحالية',
                    value: info.currentStreakDays.toString(),
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: QuranReadingStatBox(
                    title: 'الأوراد\nالمكتملة',
                    value: info.completedWirds.toString(),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: QuranReadingStatBox(
                    title: 'الصفحات\nالمقروءة',
                    value: info.readPages.toString(),
                    icon: Icons.bookmark_rounded,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            QuranNearestKhatmaProgressCard(
              progress: info.nearestKhatmaProgress,
              percent: info.nearestKhatmaProgressPercent,
            ),
          ],
        ),
      ),
    );
  }
}
