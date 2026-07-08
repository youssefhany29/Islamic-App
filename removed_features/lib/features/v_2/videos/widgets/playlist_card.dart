import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/youtube_playlist_model.dart';
import 'video_network_image.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class PlaylistCard extends StatelessWidget {
  final YoutubePlaylistModel playlist;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.thumbnailUrl,
  });

  bool get hasThumbnail {
    return thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: Container(
          width: 130.w,
          height: 68.h,
          padding: EdgeInsets.all(7.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: hasThumbnail
                    ? VideoNetworkImage(
                  imageUrl: thumbnailUrl!,
                  borderRadius: BorderRadius.circular(14.r),
                  icon: Icons.playlist_play_rounded,
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: Image.asset(
                    playlist.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xff171B26),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.playlist_play_rounded,
                          color: Colors.white.withOpacity(0.72),
                          size: 28.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  playlist.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.25
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