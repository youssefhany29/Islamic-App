import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/memorization/my_lessons_home_page.dart';
import 'package:islamic_app/features/recitations/pages/recitations_home_page.dart';
import 'package:islamic_app/features/videos/models/video_content_type.dart';
import 'package:islamic_app/features/videos/pages/videos_home_page.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'package:islamic_app/features/home/presentation/widgets/video_widgets/video_componets.dart';

class AppVideoWidget extends StatelessWidget {
  const AppVideoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayoutConstants.mainCardWidth,
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(
                child: AppVideoTile(
                  type: AppVideoTileType.recitations,
                  isWide: false,
                ),
              ),
              _VideoGap(),
              Expanded(
                child: AppVideoTile(
                  type: AppVideoTileType.podcasts,
                  isWide: false,
                ),
              ),
            ],
          ),
          _VideoVerticalGap(),
          AppVideoTile(
            type: AppVideoTileType.lessons,
            isWide: true,
          ),
        ],
      ),
    );
  }
}

class AppVideoTile extends StatelessWidget {
  const AppVideoTile({
    super.key,
    required this.type,
    required this.isWide,
  });

  final AppVideoTileType type;
  final bool isWide;

  void _openRecitationsPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecitationsHomePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _openPodcastsPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VideosHomePage(
          type: VideoContentType.podcasts,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _openMyLessonsPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MyLessonsHomePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide
          ? AppLayoutConstants.mainCardWidth
          : AppLayoutConstants.halfCardWidth,
      child: VideoComponents(
        onTap: () {
          switch (type) {
            case AppVideoTileType.recitations:
              _openRecitationsPage(context);
              break;
            case AppVideoTileType.podcasts:
              _openPodcastsPage(context);
              break;
            case AppVideoTileType.lessons:
              _openMyLessonsPage(context);
              break;
          }
        },
        width: isWide ? double.infinity : null,
        height: 90.h,
        imageWidth: isWide ? 220.w : null,
        imageHeight: 72.h,
        category: Category(
          image: _image,
          text: _text,
        ),
      ),
    );
  }

  String get _image {
    switch (type) {
      case AppVideoTileType.recitations:
        return 'assets/icons/streaming.png';
      case AppVideoTileType.podcasts:
        return 'assets/icons/porcaster.png';
      case AppVideoTileType.lessons:
        return 'assets/icons/man.png';
    }
  }

  String get _text {
    switch (type) {
      case AppVideoTileType.recitations:
        return 'تلاوة';
      case AppVideoTileType.podcasts:
        return 'بودكاست';
      case AppVideoTileType.lessons:
        return 'حلقة الحفظ';
    }
  }
}

enum AppVideoTileType {
  recitations,
  podcasts,
  lessons,
}

class _VideoGap extends StatelessWidget {
  const _VideoGap();

  @override
  Widget build(BuildContext context) => SizedBox(width: 16.w);
}

class _VideoVerticalGap extends StatelessWidget {
  const _VideoVerticalGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: 16.h);
}
