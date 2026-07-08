import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/features/videos/pages/youtube_video_player_page.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/youtube_playlist_model.dart';
import '../models/youtube_video_model.dart';
import '../services/video_progress_storage.dart';
import '../services/videos_repository.dart';
import '../widgets/continue_watching_card.dart';
import '../widgets/video_card.dart';
import '../widgets/video_page_header.dart';
import '../widgets/video_search_box.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class PlaylistVideosPage extends StatefulWidget {
  final YoutubePlaylistModel playlist;

  const PlaylistVideosPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistVideosPage> createState() => _PlaylistVideosPageState();
}

class _PlaylistVideosPageState extends State<PlaylistVideosPage> {
  final TextEditingController searchController = TextEditingController();

  List<YoutubeVideoModel> videos = [];
  String searchText = '';
  String? lastVideoId;
  double lastVideoProgress = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVideos();
    loadLastVideo();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadVideos() async {
    setState(() {
      isLoading = true;
    });

    final loadedVideos = await VideosRepository.getPlaylistVideos(
      playlist: widget.playlist,
    );

    if (!mounted) return;

    setState(() {
      videos = loadedVideos;
      isLoading = false;
    });

    await loadLastVideo();
  }

  Future<void> loadLastVideo() async {
    final savedVideoId = await VideoProgressStorage.getLastVideoId(
      widget.playlist.playlistId,
    );

    double progress = 0;

    if (savedVideoId != null) {
      progress = await VideoProgressStorage.getVideoProgressPercent(
        savedVideoId,
      );
    }

    if (!mounted) return;

    setState(() {
      lastVideoId = savedVideoId;
      lastVideoProgress = progress;
    });
  }

  List<YoutubeVideoModel> get filteredVideos {
    final text = searchText.trim();

    if (text.isEmpty) {
      return videos;
    }

    return videos.where((video) {
      return video.title.contains(text) || video.channelTitle.contains(text);
    }).toList();
  }

  YoutubeVideoModel? get lastVideo {
    if (lastVideoId == null) return null;

    try {
      return videos.firstWhere((video) => video.id == lastVideoId);
    } catch (_) {
      return null;
    }
  }

  Future<void> openVideo(YoutubeVideoModel video) async {
    await VideoProgressStorage.saveLastVideo(
      playlistId: widget.playlist.playlistId,
      videoId: video.id,
    );

    if (!mounted) return;

    setState(() {
      lastVideoId = video.id;
    });

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            YoutubeVideoPlayerPage(
              video: video,
              playlistId: widget.playlist.playlistId,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    await loadLastVideo();
  }

  Future<void> openLastVideoInYoutube() async {
    final video = lastVideo;

    if (video == null) return;

    final uri = Uri.parse(video.youtubeUrl);

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
    final filtered = filteredVideos;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              VideoPageHeader(
                title: widget.playlist.title,
              ),

              SizedBox(height: 8.h),

              ContinueWatchingCard(
                video: lastVideo,
                progressPercent: lastVideoProgress,
                onTap: lastVideo == null
                    ? null
                    : () {
                  openVideo(lastVideo!);
                },
                onOpenYoutube:
                lastVideo == null ? null : openLastVideoInYoutube,
              ),

              SizedBox(height: 16.h),

              VideoSearchBox(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                onClear: clearSearch,
              ),

              SizedBox(height: 12.h),

              Expanded(
                child: isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
                    : filtered.isEmpty
                    ? Center(
                  child: Text(
                    'لا توجد نتائج',
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.65)
),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: loadVideos,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final video = filtered[index];

                      return VideoCard(
                        video: video,
                        onTap: () {
                          openVideo(video);
                        },
                      );
                    },
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