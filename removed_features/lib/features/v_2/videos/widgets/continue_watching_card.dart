import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/youtube_video_model.dart';
import 'video_network_image.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class ContinueWatchingCard extends StatelessWidget {
  final YoutubeVideoModel? video;
  final double progressPercent;
  final VoidCallback? onTap;
  final VoidCallback? onOpenYoutube;

  const ContinueWatchingCard({
    super.key,
    required this.video,
    required this.progressPercent,
    this.onTap,
    this.onOpenYoutube,
  });

  bool get hasVideo {
    return video != null;
  }

  bool get hasThumbnail {
    return video != null && video!.thumbnailUrl.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = progressPercent.clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasVideo
            ? () {
          AppHaptics.tap(context);
          onTap?.call();
        }
            : null,
        child: SizedBox(
          width: double.infinity,
          height: 142.h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasThumbnail)
                VideoNetworkImage(
                  imageUrl: video!.thumbnailUrl,
                  borderRadius: BorderRadius.zero,
                  icon: Icons.ondemand_video_rounded,
                )
              else
                const _FallbackBackground(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.42),
                      Colors.black.withOpacity(0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.48),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'تابع المشاهدة',
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                      color: Colors.white
),
                  ),
                ),
              ),
              if (hasVideo && onOpenYoutube != null)
                Positioned(
                  left: 10.w,
                  top: 10.h,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () {
                      AppHaptics.tap(context);
                      onOpenYoutube?.call();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.52),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 12.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'YouTube',
                            style: AppTextStyles.caption(context).copyWith(
color: Colors.white,
                              fontWeight: FontWeight.w700
),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: hasVideo
                    ? Icon(
                  Icons.play_circle_fill_rounded,
                  size: 46.sp,
                  color: Colors.white,
                )
                    : Text(
                  'لا يوجد فيديو محفوظ بعد',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
color: Colors.white70,
                    fontWeight: FontWeight.w700
),
                ),
              ),
              if (hasVideo)
                Positioned(
                  left: 12.w,
                  right: 12.w,
                  bottom: 16.h,
                  child: Text(
                    video!.title,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25
),
                  ),
                ),
              if (hasVideo)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 5.h,
                    color: Colors.white.withOpacity(0.26),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: safeProgress,
                      child: Container(
                        color: const Color(0xff21C58E),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Icon(
        Icons.ondemand_video_rounded,
        size: 42.sp,
        color: Colors.white.withOpacity(0.62),
      ),
    );
  }
}