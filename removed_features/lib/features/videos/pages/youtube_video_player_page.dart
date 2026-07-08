import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/youtube_video_model.dart';
import '../services/video_progress_storage.dart';
import '../services/video_settings_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class YoutubeVideoPlayerPage extends StatefulWidget {
  final YoutubeVideoModel video;
  final String playlistId;

  const YoutubeVideoPlayerPage({
    super.key,
    required this.video,
    required this.playlistId,
  });

  @override
  State<YoutubeVideoPlayerPage> createState() => _YoutubeVideoPlayerPageState();
}

class _YoutubeVideoPlayerPageState extends State<YoutubeVideoPlayerPage> {
  YoutubePlayerController? controller;

  Timer? saveProgressTimer;

  bool preferHd = false;
  bool isMuted = false;
  bool isPlaying = true;
  bool isInitializing = true;
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final savedPreferHd = await VideoSettingsStorage.getPreferHd();

    if (!mounted) return;

    preferHd = savedPreferHd;

    final newController = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,

        // ده أسرع مشغل كان شغال عندك.
        hideControls: false,
        controlsVisibleAtStart: true,

        forceHD: preferHd,
        hideThumbnail: false,
        disableDragSeek: false,
        loop: false,
        useHybridComposition: true,
      ),
    );

    controller = newController;
    controller!.addListener(_playerListener);

    final savedPosition =
    await VideoProgressStorage.getVideoPositionSeconds(widget.video.id);

    if (savedPosition > 5) {
      controller!.seekTo(Duration(seconds: savedPosition));
    }

    await VideoProgressStorage.saveLastVideo(
      playlistId: widget.playlistId,
      videoId: widget.video.id,
    );

    if (!mounted) return;

    setState(() {
      isInitializing = false;
    });

    _startProgressSavingTimer();
  }

  void _startProgressSavingTimer() {
    saveProgressTimer?.cancel();

    saveProgressTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        _saveCurrentProgress();
      },
    );
  }

  Future<void> _saveCurrentProgress() async {
    final currentController = controller;

    if (currentController == null) return;

    final positionSeconds = currentController.value.position.inSeconds;
    final durationSeconds = currentController.metadata.duration.inSeconds;

    await VideoProgressStorage.saveLastVideo(
      playlistId: widget.playlistId,
      videoId: widget.video.id,
    );

    await VideoProgressStorage.saveVideoPosition(
      videoId: widget.video.id,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
    );
  }

  void _playerListener() {
    final currentController = controller;

    if (currentController == null || !mounted) return;

    final value = currentController.value;

    final playingNow = value.isPlaying;

    if (playingNow != isPlaying) {
      setState(() {
        isPlaying = playingNow;
      });
    }

    final fullScreenNow = value.isFullScreen;

    if (fullScreenNow != isFullScreen) {
      setState(() {
        isFullScreen = fullScreenNow;
      });

      if (fullScreenNow) {
        _forceBlackSystemBars();
      } else {
        _restoreSystemBars();
      }
    }
  }

  void _forceBlackSystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  void _restoreSystemBars() {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.background;

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarDividerColor: backgroundColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  @override
  void dispose() {
    saveProgressTimer?.cancel();

    _saveCurrentProgress();

    controller?.removeListener(_playerListener);
    controller?.dispose();

    _restoreSystemBars();

    super.dispose();
  }

  void _goBack() {
    AppHaptics.tap(context);

    final currentController = controller;

    if (currentController != null && currentController.value.isFullScreen) {
      currentController.toggleFullScreenMode();
      return;
    }

    Navigator.pop(context);
  }

  void _togglePlayPause() {
    AppHaptics.tap(context);

    final currentController = controller;

    if (currentController == null) return;

    if (currentController.value.isPlaying) {
      currentController.pause();
    } else {
      currentController.play();
    }
  }

  void _toggleMute() {
    AppHaptics.tap(context);

    final currentController = controller;

    if (currentController == null) return;

    if (isMuted) {
      currentController.unMute();
    } else {
      currentController.mute();
    }

    setState(() {
      isMuted = !isMuted;
    });
  }

  void _openFullScreen() {
    AppHaptics.tap(context);

    final currentController = controller;

    if (currentController == null) return;

    _forceBlackSystemBars();
    currentController.toggleFullScreenMode();
  }

  Future<void> _togglePreferHd() async {
    AppHaptics.tap(context);

    final newValue = !preferHd;

    await VideoSettingsStorage.setPreferHd(newValue);

    if (!mounted) return;

    setState(() {
      preferHd = newValue;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          bottom: 18.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        content: Text(
          newValue
              ? 'تم تفعيل محاولة تشغيل الجودة الأعلى عند الإمكان'
              : 'تم إيقاف محاولة تشغيل الجودة الأعلى',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(context).copyWith(
color: Colors.white
),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _retryPlayer() async {
    AppHaptics.tap(context);

    saveProgressTimer?.cancel();

    final oldController = controller;

    oldController?.removeListener(_playerListener);
    oldController?.dispose();

    if (!mounted) return;

    setState(() {
      controller = null;
      isInitializing = true;
      isPlaying = true;
      isMuted = false;
      isFullScreen = false;
    });

    _restoreSystemBars();

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    await _initPlayer();
  }

  Future<void> _openInYoutube() async {
    AppHaptics.tap(context);

    await _openExternalUrl(widget.video.youtubeUrl);
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

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final cardColor = Theme.of(context).colorScheme.primary;

    final currentController = controller;

    return WillPopScope(
      onWillPop: () async {
        final currentController = controller;

        if (currentController != null && currentController.value.isFullScreen) {
          currentController.toggleFullScreenMode();
          return false;
        }

        return true;
      },
      child: Scaffold(
        backgroundColor: isFullScreen ? Colors.black : backgroundColor,
        body: SafeArea(
          top: !isFullScreen,
          bottom: !isFullScreen,
          child: currentController == null || isInitializing
              ? _InitialLoadingView(
            textColor: textColor,
            onBack: _goBack,
          )
              : YoutubePlayerBuilder(
            onEnterFullScreen: () {
              if (!mounted) return;

              setState(() {
                isFullScreen = true;
              });

              _forceBlackSystemBars();
            },
            onExitFullScreen: () {
              if (!mounted) return;

              setState(() {
                isFullScreen = false;
              });

              _restoreSystemBars();
            },
            player: YoutubePlayer(
              controller: currentController,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xff21C58E),
              progressColors: const ProgressBarColors(
                playedColor: Color(0xff21C58E),
                handleColor: Color(0xff21C58E),
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
              onReady: () {
                if (!mounted) return;

                setState(() {
                  isPlaying = currentController.value.isPlaying;
                });
              },
            ),
            builder: (context, player) {
              return Column(
                children: [
                  if (!isFullScreen) ...[
                    _PlayerHeader(
                      title: 'المشاهدة',
                      textColor: textColor,
                      onBack: _goBack,
                    ),
                    SizedBox(height: 10.h),
                  ],

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isFullScreen ? 0 : 14.w,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        isFullScreen ? 0 : 16.r,
                      ),
                      child: ColoredBox(
                        color: Colors.black,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: player,
                        ),
                      ),
                    ),
                  ),

                  if (!isFullScreen) ...[
                    SizedBox(height: 10.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _PlayerActionButton(
                                icon: isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                label: isPlaying ? 'إيقاف' : 'تشغيل',
                                onTap: _togglePlayPause,
                              ),
                            ),
                            Expanded(
                              child: _PlayerActionButton(
                                icon: isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                label: isMuted ? 'الصوت' : 'كتم',
                                onTap: _toggleMute,
                              ),
                            ),
                            Expanded(
                              child: _PlayerActionButton(
                                icon: Icons.fullscreen_rounded,
                                label: 'ملء الشاشة',
                                onTap: _openFullScreen,
                              ),
                            ),
                            Expanded(
                              child: _PlayerActionButton(
                                icon: preferHd
                                    ? Icons.hd_rounded
                                    : Icons.sd_rounded,
                                label:
                                preferHd ? 'HD مفعل' : 'جودة أسرع',
                                onTap: _togglePreferHd,
                              ),
                            ),
                            Expanded(
                              child: _YoutubeIconOnlyButton(
                                onTap: _openInYoutube,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.video.title,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.4
),
                                ),

                                SizedBox(height: 8.h),

                                Text(
                                  widget.video.channelTitle,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context).copyWith(
color: Colors.white.withOpacity(0.78)
),
                                ),

                                if (widget.video.publishedText
                                    .trim()
                                    .isNotEmpty) ...[
                                  SizedBox(height: 6.h),
                                  Text(
                                    widget.video.publishedText,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: AppTextStyles.caption(context).copyWith(
color:
                                      Colors.white.withOpacity(0.65)
),
                                  ),
                                ],

                                SizedBox(height: 10.h),

                                Text(
                                  'للوصول لإعدادات YouTube الكاملة مثل الجودة والسرعة والترجمة، استخدم زر لينك الحلقة لفتح الفيديو في YouTube الرسمي.',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.caption(context).copyWith(
color: Colors.white.withOpacity(0.55),
                                    height: 1.4
),
                                ),

                                SizedBox(height: 12.h),

                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 9.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.18),
                                    borderRadius:
                                    BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color:
                                      Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Text(
                                    'حقوق الفيديو والقناة محفوظة لأصحابها على YouTube. التطبيق لا يعيد رفع الفيديو، ويمكن فتح الحلقة في YouTube الرسمي من الزر الموجود أعلى هذا الكارت.',
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: AppTextStyles.caption(context).copyWith(
color:
                                      Colors.white.withOpacity(0.70),
                                      height: 1.45
),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: ColoredBox(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InitialLoadingView extends StatelessWidget {
  final Color textColor;
  final VoidCallback onBack;

  const _InitialLoadingView({
    required this.textColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlayerHeader(
          title: 'المشاهدة',
          textColor: textColor,
          onBack: onBack,
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xff21C58E),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  final VoidCallback onBack;

  const _PlayerHeader({
    required this.title,
    required this.textColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: 14.w,
        left: 14.w,
        top: 14.h,
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 38.w,
              minHeight: 38.h,
            ),
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.body(context).copyWith(
fontWeight: FontWeight.w700,
                color: textColor
),
            ),
          ),
          SizedBox(
            width: 38.w,
            height: 38.h,
          ),
        ],
      ),
    );
  }
}

class _PlayerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 1.w,
          vertical: 4.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(height: 3.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85)
),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YoutubeIconOnlyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _YoutubeIconOnlyButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 1.w,
          vertical: 4.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18.w,
              height: 18.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffFF0000),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 11.sp,
              ),
            ),
            SizedBox(height: 3.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'لينك الحلقة',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85)
),
              ),
            ),
          ],
        ),
      ),
    );
  }
}