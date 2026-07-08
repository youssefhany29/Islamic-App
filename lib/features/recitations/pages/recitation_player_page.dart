import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/reciter_model.dart';
import '../services/recitation_api_service.dart';
import '../services/recitation_audio_controller.dart';
import '../services/recitation_download_service.dart';
import '../services/recitation_favorites_storage.dart';
import '../services/recitation_sleep_timer_service.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'recitation_player_widgets.dart';

class RecitationPlayerPage extends StatefulWidget {
  final int reciterId;
  final String reciterName;
  final RecitationSource reciterSource;
  final String mp3QuranServerUrl;
  final int surahNumber;
  final String surahName;
  final Duration startPosition;
  final String? initialAudioUrl;
  final String? localFilePath;
  final bool autoPlay;

  const RecitationPlayerPage({
    super.key,
    required this.reciterId,
    required this.reciterName,
    required this.reciterSource,
    required this.mp3QuranServerUrl,
    required this.surahNumber,
    required this.surahName,
    this.startPosition = Duration.zero,
    this.initialAudioUrl,
    this.localFilePath,
    this.autoPlay = false,
  });

  @override
  State<RecitationPlayerPage> createState() => _RecitationPlayerPageState();
}

class _RecitationPlayerPageState extends State<RecitationPlayerPage> {
  final RecitationAudioController audioController =
      RecitationAudioController.instance;

  bool hasError = false;
  bool isPreparing = false;
  bool hasStartedPlayback = false;

  bool isDownloaded = false;
  bool isDownloading = false;
  bool isFavorite = false;

  double downloadProgress = 0;

  String? downloadedLocalFilePath;
  String? downloadedAudioUrl;

  Timer? saveProgressTimer;
  CancelToken? downloadCancelToken;

  bool get isOfflineMode {
    final localPath = widget.localFilePath ?? downloadedLocalFilePath;
    return localPath != null && localPath.trim().isNotEmpty;
  }

  bool get _isCurrentThisRecitation {
    final currentInfo = audioController.currentInfo;

    if (currentInfo == null) return false;

    return currentInfo.reciterId == widget.reciterId &&
        currentInfo.reciterSource == widget.reciterSource &&
        currentInfo.surahNumber == widget.surahNumber;
  }

  @override
  void initState() {
    super.initState();

    hasStartedPlayback = _isCurrentThisRecitation;

    _loadDownloadState();
    _loadFavoriteState();

    if (widget.autoPlay && !hasStartedPlayback) {
      _startPlayback();
    }

    saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      audioController.saveCurrentProgress();
    });
  }

  @override
  void dispose() {
    saveProgressTimer?.cancel();

    if (downloadCancelToken != null && !downloadCancelToken!.isCancelled) {
      downloadCancelToken!.cancel('تم إيقاف التحميل');
    }

    audioController.saveCurrentProgress();

    // لا نعمل stop هنا عشان الصوت يفضل شغال بعد الرجوع.
    super.dispose();
  }

  Future<void> _loadDownloadState() async {
    final downloaded = await RecitationDownloadService.getDownload(
      reciterId: widget.reciterId,
      source: widget.reciterSource,
      surahNumber: widget.surahNumber,
    );

    if (!mounted) return;

    setState(() {
      isDownloaded =
          downloaded != null ||
          (widget.localFilePath != null &&
              widget.localFilePath!.trim().isNotEmpty);
      downloadedLocalFilePath = downloaded?.localFilePath;
      downloadedAudioUrl = downloaded?.audioUrl;
    });
  }

  Future<void> _loadFavoriteState() async {
    final favorite = await RecitationFavoritesStorage.isFavoriteSurah(
      reciterId: widget.reciterId,
      reciterSource: widget.reciterSource,
      surahNumber: widget.surahNumber,
    );

    if (!mounted) return;

    setState(() {
      isFavorite = favorite;
    });
  }

  Future<void> _toggleFavorite() async {
    AppHaptics.tap(context);

    await RecitationFavoritesStorage.toggleSurahFavorite(
      reciterId: widget.reciterId,
      reciterName: widget.reciterName,
      reciterSource: widget.reciterSource,
      mp3QuranServerUrl: widget.mp3QuranServerUrl,
      surahNumber: widget.surahNumber,
      surahName: widget.surahName,
    );

    await _loadFavoriteState();

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar(
        context,
        isFavorite
            ? 'تمت إضافة سورة ${widget.surahName} إلى المفضلة'
            : 'تمت إزالة سورة ${widget.surahName} من المفضلة',
        isError: false,
      ),
    );
  }

  Future<void> _startPlayback() async {
    try {
      setState(() {
        hasError = false;
        isPreparing = true;
      });

      await audioController.playRecitation(
        reciterId: widget.reciterId,
        reciterName: widget.reciterName,
        reciterSource: widget.reciterSource,
        mp3QuranServerUrl: widget.mp3QuranServerUrl,
        surahNumber: widget.surahNumber,
        surahName: widget.surahName,
        startPosition: widget.startPosition,
        initialAudioUrl: widget.initialAudioUrl ?? downloadedAudioUrl,
        localFilePath: widget.localFilePath ?? downloadedLocalFilePath,
      );

      if (!mounted) return;

      setState(() {
        hasStartedPlayback = true;
        isPreparing = false;
        hasError = false;
      });
    } catch (error) {
      debugPrint('❌ Recitation player error: $error');

      if (!mounted) return;

      setState(() {
        isPreparing = false;
        hasError = true;
      });
    }
  }

  Future<void> _handleMainPlayPause() async {
    AppHaptics.tap(context);

    if (_isCurrentThisRecitation || hasStartedPlayback) {
      await audioController.togglePlayPause();

      if (!mounted) return;

      setState(() {
        hasStartedPlayback = true;
      });

      return;
    }

    await _startPlayback();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) return '$hours:$minutes:$seconds';

    return '$minutes:$seconds';
  }

  Future<void> _retry() async {
    AppHaptics.tap(context);
    await _startPlayback();
  }

  Future<void> _stopPlayback() async {
    AppHaptics.tap(context);

    RecitationSleepTimerService.instance.cancel();

    if (_isCurrentThisRecitation || hasStartedPlayback) {
      await audioController.stop();
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> _downloadCurrentSurah() async {
    if (isDownloaded || isDownloading) return;

    AppHaptics.tap(context);

    final cancelToken = CancelToken();
    downloadCancelToken = cancelToken;

    setState(() {
      isDownloading = true;
      downloadProgress = 0;
    });

    try {
      final audioFile = await RecitationApiService.getChapterAudioFile(
        reciterId: widget.reciterId,
        source: widget.reciterSource,
        chapterNumber: widget.surahNumber,
        mp3QuranServerUrl: widget.mp3QuranServerUrl,
      );

      await RecitationDownloadService.downloadSurah(
        reciterId: widget.reciterId,
        reciterName: widget.reciterName,
        reciterSource: widget.reciterSource,
        mp3QuranServerUrl: widget.mp3QuranServerUrl,
        surahNumber: widget.surahNumber,
        surahName: widget.surahName,
        audioUrl: audioFile.audioUrl,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total <= 0) return;

          setState(() {
            downloadProgress = received / total;
          });
        },
      );

      await _loadDownloadState();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          context,
          'تم تحميل سورة ${widget.surahName} بنجاح',
          isError: false,
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;

      final isCancelled = CancelToken.isCancel(error);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          context,
          isCancelled
              ? 'تم إيقاف تحميل سورة ${widget.surahName}'
              : 'تعذر تحميل السورة، حاول مرة أخرى',
          isError: !isCancelled,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(context, 'تعذر تحميل السورة، حاول مرة أخرى', isError: true),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isDownloading = false;
        downloadProgress = 0;
        downloadCancelToken = null;
      });
    }
  }

  void _cancelDownload() {
    AppHaptics.tap(context);

    if (downloadCancelToken != null && !downloadCancelToken!.isCancelled) {
      downloadCancelToken!.cancel('تم إيقاف التحميل');
    }
  }

  SnackBar _snackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError
          ? Colors.redAccent
          : Theme.of(context).colorScheme.primary,
      elevation: 0,
      margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  void _openSleepTimerSheet() {
    AppHaptics.tap(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SleepTimerSheet(
          onSelect: (duration) {
            AppHaptics.tap(context);

            Navigator.pop(sheetContext);

            RecitationSleepTimerService.instance.start(
              duration: duration,
              onFinished: () async {
                await audioController.stop();
              },
            );
          },
          onCancel: () {
            AppHaptics.tap(context);

            RecitationSleepTimerService.instance.cancel();
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 38.w,
                        minHeight: 38.h,
                      ),
                      onPressed: () {
                        AppHaptics.tap(context);
                        audioController.saveCurrentProgress();
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: textColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'الاستماع',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 38.w,
                        minHeight: 38.h,
                      ),
                      onPressed: _stopPlayback,
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        size: 22.sp,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38.r,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 38.sp,
                        color: primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'سورة ${widget.surahName}',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      widget.reciterName,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: Colors.white.withOpacity(0.75)),
                    ),
                    if (isOfflineMode) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'متاحة بدون إنترنت',
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: Colors.white.withOpacity(0.65)),
                      ),
                    ],
                    SizedBox(height: 22.h),
                    if (hasError)
                      Column(
                        children: [
                          Text(
                            isOfflineMode
                                ? 'تعذر تشغيل الملف المحمل، حاول حذفه وتحميله مرة أخرى'
                                : 'تعذر تشغيل التلاوة، تأكد من اتصال الإنترنت وحاول مرة أخرى',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(color: Colors.white, height: 1.6),
                          ),
                          SizedBox(height: 10.h),
                          ElevatedButton(
                            onPressed: _retry,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      )
                    else
                      StreamBuilder<RecitationAudioState>(
                        stream: audioController.audioStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;

                          final bool thisIsCurrent = _isCurrentThisRecitation;

                          final position = thisIsCurrent
                              ? state?.position ??
                                    audioController.player.position
                              : widget.startPosition;

                          final duration = thisIsCurrent
                              ? state?.duration ?? Duration.zero
                              : Duration.zero;

                          final playing =
                              thisIsCurrent && (state?.playing ?? false);
                          final loading =
                              isPreparing || (state?.loading ?? false);

                          final showPreparingMessage =
                              loading && !playing && position.inSeconds <= 1;

                          final showConnectionWarning =
                              !isOfflineMode &&
                              thisIsCurrent &&
                              (state?.connectionWarning ?? false);

                          return Column(
                            children: [
                              _ProgressSection(
                                position: position,
                                duration: duration,
                                formatDuration: _formatDuration,
                                onSeek: thisIsCurrent
                                    ? audioController.seekTo
                                    : (_) {},
                              ),
                              SizedBox(height: 18.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: !thisIsCurrent
                                        ? null
                                        : () {
                                            AppHaptics.tap(context);
                                            audioController.seekBackward();
                                          },
                                    icon: Icon(
                                      Icons.replay_10_rounded,
                                      color: !thisIsCurrent
                                          ? Colors.white.withOpacity(0.35)
                                          : Colors.white,
                                      size: 32.sp,
                                    ),
                                  ),
                                  SizedBox(width: 18.w),
                                  CircleAvatar(
                                    radius: 30.r,
                                    backgroundColor: Colors.white,
                                    child: IconButton(
                                      onPressed: showPreparingMessage
                                          ? null
                                          : _handleMainPlayPause,
                                      icon: Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: primary.withOpacity(
                                          showPreparingMessage ? 0.45 : 1,
                                        ),
                                        size: 34.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 18.w),
                                  IconButton(
                                    onPressed: !thisIsCurrent
                                        ? null
                                        : () {
                                            AppHaptics.tap(context);
                                            audioController.seekForward();
                                          },
                                    icon: Icon(
                                      Icons.forward_10_rounded,
                                      color: !thisIsCurrent
                                          ? Colors.white.withOpacity(0.35)
                                          : Colors.white,
                                      size: 32.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      _SleepTimerButton(
                                        onTap: _openSleepTimerSheet,
                                      ),

                                      SizedBox(width: 6.w),

                                      _DownloadButton(
                                        isDownloaded: isDownloaded,
                                        isDownloading: isDownloading,
                                        progress: downloadProgress,
                                        onTap: isDownloading
                                            ? _cancelDownload
                                            : _downloadCurrentSurah,
                                      ),

                                      SizedBox(width: 6.w),

                                      _FavoriteButton(
                                        isFavorite: isFavorite,
                                        onTap: _toggleFavorite,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!thisIsCurrent &&
                                  widget.startPosition.inSeconds > 5) ...[
                                SizedBox(height: 10.h),
                                Text(
                                  'جاهز من آخر موضع: ${_formatDuration(widget.startPosition)}',
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                ),
                              ],
                              if (showPreparingMessage) ...[
                                SizedBox(height: 10.h),
                                Text(
                                  'جاري تجهيز التلاوة...',
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                ),
                              ],

                              if (showConnectionWarning) ...[
                                SizedBox(height: 10.h),
                                Text(
                                  'الاتصال بالإنترنت غير مستقر، تأكد من الشبكة',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: Colors.white.withOpacity(0.82),
                                      ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'افتح السورة ثم اضغط تشغيل عند الاستعداد. يمكنك الرجوع وسيستمر التشغيل.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: textColor.withOpacity(0.55), height: 1.5),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
