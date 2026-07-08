import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/videos/pages/youtube_video_player_page.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/video_mock_data.dart';
import '../models/video_content_type.dart';
import '../models/youtube_playlist_model.dart';
import '../models/youtube_video_model.dart';
import '../services/cached_playlists_api_service.dart';
import '../services/video_progress_storage.dart';
import '../services/videos_repository.dart';
import '../widgets/continue_watching_card.dart';
import '../widgets/playlist_card.dart';
import '../widgets/video_cache_notice.dart';
import '../widgets/video_card.dart';
import '../widgets/video_network_image.dart';
import '../widgets/video_page_header.dart';
import '../widgets/video_search_box.dart';
import 'playlist_videos_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class VideosHomePage extends StatefulWidget {
  final VideoContentType type;

  const VideosHomePage({
    super.key,
    required this.type,
  });

  @override
  State<VideosHomePage> createState() => _VideosHomePageState();
}

class _VideosHomePageState extends State<VideosHomePage> {
  final TextEditingController searchController = TextEditingController();

  List<YoutubePlaylistModel> playlists = [];
  List<YoutubeVideoModel> videos = [];

  String searchText = '';
  String? globalLastVideoId;
  double globalLastVideoProgress = 0;

  bool isLoading = false;
  bool isLoadingPlaylists = true;
  bool isUsingCacheFallback = false;

  final Map<String, String> playlistThumbnails = {};

  bool get isVideosPage => widget.type == VideoContentType.videos;

  @override
  void initState() {
    super.initState();

    // التحميل يحصل عند فتح صفحة الفيديوهات فقط، مش عند فتح التطبيق كله.
    loadPageData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadPageData({
    bool forceRefresh = false,
  }) async {
    await loadPlaylists();

    if (isVideosPage) {
      await loadMergedVideos(forceRefresh: forceRefresh);
      await loadGlobalLastVideo();
    } else {
      await loadPodcastPlaylistThumbnails();
    }
  }

  Future<void> loadPlaylists() async {
    if (mounted) {
      setState(() {
        isLoadingPlaylists = true;
      });
    }

    try {
      final loadedPlaylists = await CachedPlaylistsApiService.getPlaylists(
        type: widget.type,
      );

      if (!mounted) return;

      setState(() {
        playlists = loadedPlaylists;
        isUsingCacheFallback =
            CachedPlaylistsApiService.lastLoadUsedCacheFallback;
        isLoadingPlaylists = false;
      });
    } catch (error) {
      debugPrint('❌ Failed to load playlists from backend: $error');
      debugPrint('⚠️ Using fallback playlists');

      final fallbackPlaylists = VideoMockData.playlistsByType(widget.type);

      if (!mounted) return;

      setState(() {
        playlists = fallbackPlaylists;
        isUsingCacheFallback = false;
        isLoadingPlaylists = false;
      });
    }
  }

  Future<void> loadPodcastPlaylistThumbnails() async {
    if (playlists.isEmpty) return;

    final results = await Future.wait(
      playlists.map((playlist) async {
        final playlistVideos = await VideosRepository.getPlaylistVideos(
          playlist: playlist,
          maxResults: 1,
        );

        if (playlistVideos.isEmpty) {
          return null;
        }

        return MapEntry(
          playlist.playlistId,
          playlistVideos.first.thumbnailUrl,
        );
      }),
    );

    if (!mounted) return;

    setState(() {
      for (final result in results) {
        if (result != null && result.value.trim().isNotEmpty) {
          playlistThumbnails[result.key] = result.value;
        }
      }

      if (VideosRepository.lastPlaylistVideosUsedCacheFallback) {
        isUsingCacheFallback = true;
      }
    });
  }

  Future<void> loadGlobalLastVideo() async {
    final savedVideoId = await VideoProgressStorage.getGlobalLastVideoId();

    double progress = 0;

    if (savedVideoId != null) {
      progress = await VideoProgressStorage.getVideoProgressPercent(
        savedVideoId,
      );
    }

    if (!mounted) return;

    setState(() {
      globalLastVideoId = savedVideoId;
      globalLastVideoProgress = progress;
    });
  }

  Future<void> loadMergedVideos({
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final loadedVideos = await VideosRepository.getMergedVideos(
      playlists: playlists,
      maxResultsPerPlaylist: 50,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    setState(() {
      videos = loadedVideos;
      isUsingCacheFallback = VideosRepository.lastMergedVideosUsedCacheFallback;
      isLoading = false;
    });

    await loadGlobalLastVideo();
  }

  Future<void> refreshPage() async {
    playlistThumbnails.clear();

    await loadPageData(
      forceRefresh: true,
    );
  }

  List<YoutubeVideoModel> get filteredVideos {
    final text = searchText.trim().toLowerCase();

    if (text.isEmpty) {
      return videos;
    }

    return videos.where((video) {
      return video.title.toLowerCase().contains(text) ||
          video.channelTitle.toLowerCase().contains(text);
    }).toList();
  }

  YoutubeVideoModel? get lastVideo {
    if (globalLastVideoId == null) return null;

    try {
      return videos.firstWhere((video) => video.id == globalLastVideoId);
    } catch (_) {
      return null;
    }
  }

  void openPlaylist(
      BuildContext context,
      YoutubePlaylistModel playlist,
      ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlaylistVideosPage(
              playlist: playlist,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> openVideo(YoutubeVideoModel video) async {
    await VideoProgressStorage.saveLastVideo(
      playlistId: 'merged_videos',
      videoId: video.id,
    );

    if (!mounted) return;

    setState(() {
      globalLastVideoId = video.id;
    });

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            YoutubeVideoPlayerPage(
              video: video,
              playlistId: 'merged_videos',
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    await loadGlobalLastVideo();
  }

  Future<void> openLastVideoInYoutube() async {
    final video = lastVideo;

    if (video == null) return;

    await _openExternalUrl(video.youtubeUrl);
  }

  Future<void> openLastVideoChannelInYoutube() async {
    final video = lastVideo;

    if (video == null) return;

    await _openExternalUrl(video.channelUrl);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) return;

    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void clearSearch() {
    searchController.clear();

    setState(() {
      searchText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              VideoPageHeader(
                title: widget.type.arabicTitle,
              ),
              SizedBox(height: 8.h),
              VideoCacheNotice(
                visible: isUsingCacheFallback,
              ),
              Expanded(
                child: isVideosPage
                    ? _VideosFeedBody(
                  isLoading: isLoading,
                  videos: filteredVideos,
                  lastVideo: lastVideo,
                  lastVideoProgress: globalLastVideoProgress,
                  searchController: searchController,
                  onRefresh: refreshPage,
                  onVideoTap: openVideo,
                  onOpenYoutube: openLastVideoInYoutube,
                  onOpenYoutubeChannel: openLastVideoChannelInYoutube,
                  onSearchChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  onSearchClear: clearSearch,
                )
                    : _PodcastPlaylistsBody(
                  isLoading: isLoadingPlaylists,
                  playlists: playlists,
                  playlistThumbnails: playlistThumbnails,
                  onRefresh: refreshPage,
                  onPlaylistTap: (playlist) {
                    openPlaylist(context, playlist);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodcastPlaylistsBody extends StatelessWidget {
  final bool isLoading;
  final List<YoutubePlaylistModel> playlists;
  final Map<String, String> playlistThumbnails;
  final Future<void> Function() onRefresh;
  final ValueChanged<YoutubePlaylistModel> onPlaylistTap;

  const _PodcastPlaylistsBody({
    required this.isLoading,
    required this.playlists,
    required this.playlistThumbnails,
    required this.onRefresh,
    required this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (playlists.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 350,
            child: _EmptyVideosMessage(
              text: 'لا توجد قوائم بودكاست حاليًا',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 78.h,
              child: ListView.separated(
                reverse: true,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: playlists.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];

                  return PlaylistCard(
                    playlist: playlist,
                    thumbnailUrl: playlistThumbnails[playlist.playlistId],
                    onTap: () {
                      onPlaylistTap(playlist);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'قوائم البودكاست',
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onBackground
),
            ),
            SizedBox(height: 8.h),
            for (final playlist in playlists) ...[
              _PodcastPlaylistRow(
                playlist: playlist,
                thumbnailUrl: playlistThumbnails[playlist.playlistId],
                onTap: () {
                  onPlaylistTap(playlist);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideosFeedBody extends StatelessWidget {
  final bool isLoading;
  final List<YoutubeVideoModel> videos;
  final YoutubeVideoModel? lastVideo;
  final double lastVideoProgress;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final ValueChanged<YoutubeVideoModel> onVideoTap;
  final VoidCallback onOpenYoutube;
  final VoidCallback onOpenYoutubeChannel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  const _VideosFeedBody({
    required this.isLoading,
    required this.videos,
    required this.lastVideo,
    required this.lastVideoProgress,
    required this.searchController,
    required this.onRefresh,
    required this.onVideoTap,
    required this.onOpenYoutube,
    required this.onOpenYoutubeChannel,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContinueWatchingCard(
          video: lastVideo,
          progressPercent: lastVideoProgress,
          onTap: lastVideo == null
              ? null
              : () {
            onVideoTap(lastVideo!);
          },
          onOpenYoutube: lastVideo == null ? null : onOpenYoutube,
        ),
        SizedBox(height: 8.h),
        _YoutubeRightsActions(
          hasVideo: lastVideo != null,
          onOpenYoutube: onOpenYoutube,
          onOpenYoutubeChannel: onOpenYoutubeChannel,
        ),
        SizedBox(height: 10.h),
        VideoSearchBox(
          controller: searchController,
          onChanged: onSearchChanged,
          onClear: onSearchClear,
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          )
              : videos.isEmpty
              ? const _EmptyVideosMessage(
            text:
            'لا توجد فيديوهات حاليًا، تأكد من اتصال الإنترنت أو الباك إند.',
          )
              : RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: videos.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final video = videos[index];

                return VideoCard(
                  video: video,
                  onTap: () {
                    onVideoTap(video);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _YoutubeRightsActions extends StatelessWidget {
  final bool hasVideo;
  final VoidCallback onOpenYoutube;
  final VoidCallback onOpenYoutubeChannel;

  const _YoutubeRightsActions({
    required this.hasVideo,
    required this.onOpenYoutube,
    required this.onOpenYoutubeChannel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff171B26) : const Color(0xffEEF1F3),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const _YoutubeLogoMark(),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  'الفيديوهات مملوكة لأصحابها على YouTube ويتم تشغيلها من خلال مشغل YouTube الرسمي داخل التطبيق.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.72)
),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _YoutubeActionButton(
                  text: 'مشغل YouTube HD',
                  icon: Icons.high_quality_rounded,
                  enabled: hasVideo,
                  onTap: onOpenYoutube,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _YoutubeActionButton(
                  text: 'قناة YouTube',
                  enabled: hasVideo,
                  onTap: onOpenYoutubeChannel,
                  forceYoutubeRed: true,
                  leading: const _YoutubeLogoMark(
                    compact: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YoutubeActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool enabled;
  final bool forceYoutubeRed;
  final Widget? leading;
  final VoidCallback onTap;

  const _YoutubeActionButton({
    required this.text,
    required this.enabled,
    required this.onTap,
    this.icon,
    this.forceYoutubeRed = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = !enabled
        ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
        : forceYoutubeRed
        ? const Color(0xffFF0000)
        : Theme.of(context).colorScheme.primary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: enabled
            ? () {
          AppHaptics.tap(context);
          onTap();
        }
            : null,
        child: Container(
          height: 32.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              if (leading != null)
                leading!
              else
                Icon(
                  icon ?? Icons.open_in_new_rounded,
                  size: 15.sp,
                  color: Colors.white,
                ),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                    color: Colors.white
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

class _YoutubeLogoMark extends StatelessWidget {
  final bool compact;

  const _YoutubeLogoMark({
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 18.w : 24.w;
    final height = compact ? 13.h : 17.h;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffFF0000),
        borderRadius: BorderRadius.circular(4.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: compact ? 13.sp : 17.sp,
      ),
    );
  }
}

class _PodcastPlaylistRow extends StatelessWidget {
  final YoutubePlaylistModel playlist;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const _PodcastPlaylistRow({
    required this.playlist,
    required this.onTap,
    this.thumbnailUrl,
  });

  bool get hasThumbnail {
    return thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () {
          AppHaptics.tap(context);
          onTap();
        },
        child: SizedBox(
          height: 58.h,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              if (hasThumbnail)
                VideoNetworkImage(
                  imageUrl: thumbnailUrl!,
                  width: 78.w,
                  height: 50.h,
                  borderRadius: BorderRadius.circular(13.r),
                  icon: Icons.playlist_play_rounded,
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(13.r),
                  child: SizedBox(
                    width: 78.w,
                    height: 50.h,
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
                            size: 26.sp,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      playlist.title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: textColor
),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      playlist.subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
color: textColor.withOpacity(0.55)
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

class _EmptyVideosMessage extends StatelessWidget {
  final String text;

  const _EmptyVideosMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
    Theme.of(context).colorScheme.onBackground.withOpacity(0.65);

    return Center(
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption(context).copyWith(
color: textColor
),
      ),
    );
  }
}