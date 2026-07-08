import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/youtube_video_model.dart';
import 'video_network_image.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class VideoCard extends StatelessWidget {
  final YoutubeVideoModel video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black45;

    final metaParts = <String>[
      if (video.viewsText.trim().isNotEmpty) video.viewsText,
      if (video.publishedText.trim().isNotEmpty) video.publishedText,
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () {
        AppHaptics.tap(context);
        onTap();
      },
      child: SizedBox(
        height: 64.h,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            VideoNetworkImage(
              imageUrl: video.thumbnailUrl,
              width: 86.w,
              height: 50.h,
              borderRadius: BorderRadius.circular(13.r),
              icon: Icons.play_circle_fill_rounded,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.title,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.25
),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    metaParts.isEmpty ? 'فيديو' : metaParts.join(' - '),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
color: subTextColor
),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          video.channelTitle,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
color: subTextColor
),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}