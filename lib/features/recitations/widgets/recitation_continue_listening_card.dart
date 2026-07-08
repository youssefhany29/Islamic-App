import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class RecitationContinueListeningCard extends StatelessWidget {
  final Map<String, dynamic>? lastRecitation;
  final VoidCallback? onTap;

  const RecitationContinueListeningCard({
    super.key,
    required this.lastRecitation,
    required this.onTap,
  });

  static String _formatSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$secs';
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final saved = lastRecitation;
    final primary = Theme.of(context).colorScheme.primary;

    final surahName = saved == null ? null : saved['surahName'].toString();
    final reciterName = saved == null ? 'ابدأ الاستماع الآن' : saved['reciterName'].toString();
    final position = saved == null ? 0 : saved['positionSeconds'] as int;
    final duration = saved == null ? 0 : saved['durationSeconds'] as int;

    final lastPositionText = position > 5
        ? 'آخر موضع: ${_formatSeconds(position)}'
        : 'ابدأ الاستماع الآن';

    double progress = 0;
    if (duration > 0) progress = (position / duration).clamp(0.0, 1.0);

    return Material(
      color: primary,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 88.h,
          padding: EdgeInsets.all(10.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Colors.white,
                child: Icon(Icons.play_arrow_rounded, color: primary, size: 27.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'تابع الاستماع',
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: Colors.white
),
                    ),
                    SizedBox(height: 2.h),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: AppTextStyles.caption(context).copyWith(
color: Colors.white
),
                        children: [
                          const TextSpan(text: 'سورة ', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(
                            text: surahName ?? 'لا يوجد استماع محفوظ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$reciterName • $lastPositionText',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
color: Colors.white.withOpacity(0.70)
),
                    ),
                    SizedBox(height: 5.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3.h,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
