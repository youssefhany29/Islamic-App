import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../data/quran_surahs_data.dart';
import '../models/downloaded_recitation_model.dart';
import '../models/reciter_model.dart';
import '../services/recitation_audio_controller.dart';
import '../services/recitation_download_service.dart';
import '../services/recitation_progress_storage.dart';
import 'recitation_player_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class ReciterSurahsPage extends StatefulWidget {
  final ReciterModel reciter;

  const ReciterSurahsPage({super.key, required this.reciter});

  @override
  State<ReciterSurahsPage> createState() => _ReciterSurahsPageState();
}

class _ReciterSurahsPageState extends State<ReciterSurahsPage> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';

  CancelToken? downloadAllCancelToken;

  final Map<int, DownloadedRecitationModel> downloadedSurahs = {};
  final Map<int, RecitationSavedProgress> savedProgressMap = {};

  bool isDownloadingAll = false;
  String downloadingAllText = '';

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void dispose() {
    searchController.dispose();

    if (downloadAllCancelToken != null &&
        !downloadAllCancelToken!.isCancelled) {
      downloadAllCancelToken!.cancel('تم إيقاف التحميل');
    }

    super.dispose();
  }

  Future<void> _loadPageData() async {
    await Future.wait([_loadDownloadedSurahs(), _loadSavedProgressForSurahs()]);
  }

  Future<void> _loadDownloadedSurahs() async {
    final downloads = await RecitationDownloadService.getAllDownloads();

    final filteredDownloads = downloads.where((download) {
      return download.reciterId == widget.reciter.id &&
          download.reciterSource == widget.reciter.source;
    }).toList();

    if (!mounted) return;

    setState(() {
      downloadedSurahs.clear();

      for (final download in filteredDownloads) {
        downloadedSurahs[download.surahNumber] = download;
      }
    });
  }

  Future<void> _loadSavedProgressForSurahs() async {
    final availableSurahs = QuranSurahsData.surahs.where((surah) {
      return widget.reciter.hasSurah(surah.number);
    }).toList();

    final Map<int, RecitationSavedProgress> progressResult = {};

    for (final surah in availableSurahs) {
      final progress = await RecitationProgressStorage.getSavedProgressInfo(
        reciterId: widget.reciter.id,
        reciterSource: widget.reciter.source,
        surahNumber: surah.number,
      );

      if (progress.hasProgress || progress.duration.inSeconds > 0) {
        progressResult[surah.number] = progress;
      }
    }

    if (!mounted) return;

    setState(() {
      savedProgressMap
        ..clear()
        ..addAll(progressResult);
    });
  }

  List<QuranSurahInfo> get filteredSurahs {
    final allSurahs = QuranSurahsData.surahs.where((surah) {
      return widget.reciter.hasSurah(surah.number);
    }).toList();

    final text = searchText.trim();

    if (text.isEmpty) return allSurahs;

    return allSurahs.where((surah) {
      return surah.name.contains(text) || surah.number.toString() == text;
    }).toList();
  }

  bool _isCurrentSurah(QuranSurahInfo surah) {
    final currentInfo = RecitationAudioController.instance.currentInfo;

    if (currentInfo == null) return false;

    return currentInfo.reciterId == widget.reciter.id &&
        currentInfo.reciterSource == widget.reciter.source &&
        currentInfo.surahNumber == surah.number;
  }

  Duration _savedStartPosition(QuranSurahInfo surah) {
    return savedProgressMap[surah.number]?.position ?? Duration.zero;
  }

  void _openPlayer(QuranSurahInfo surah) {
    AppHaptics.tap(context);

    final downloaded = downloadedSurahs[surah.number];
    final audioController = RecitationAudioController.instance;
    final isCurrent = _isCurrentSurah(surah);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecitationPlayerPage(
              reciterId: widget.reciter.id,
              reciterName: widget.reciter.name,
              reciterSource: widget.reciter.source,
              mp3QuranServerUrl: widget.reciter.serverUrl,
              surahNumber: surah.number,
              surahName: surah.name,
              initialAudioUrl: downloaded?.audioUrl,
              localFilePath: downloaded?.localFilePath,
              startPosition: isCurrent
                  ? audioController.player.position
                  : _savedStartPosition(surah),
              autoPlay: false,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadPageData());
  }

  Future<void> _toggleSurahPlayback(QuranSurahInfo surah) async {
    AppHaptics.tap(context);

    final audioController = RecitationAudioController.instance;

    if (_isCurrentSurah(surah)) {
      await audioController.togglePlayPause();
      await _loadSavedProgressForSurahs();
      return;
    }

    final downloaded = downloadedSurahs[surah.number];

    try {
      await audioController.playRecitation(
        reciterId: widget.reciter.id,
        reciterName: widget.reciter.name,
        reciterSource: widget.reciter.source,
        mp3QuranServerUrl: widget.reciter.serverUrl,
        surahNumber: surah.number,
        surahName: surah.name,
        startPosition: _savedStartPosition(surah),
        initialAudioUrl: downloaded?.audioUrl,
        localFilePath: downloaded?.localFilePath,
      );

      await _loadSavedProgressForSurahs();
    } catch (error) {
      debugPrint('❌ Failed to play from reciter surahs page: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        _errorSnackBar(
          context,
          downloaded != null
              ? 'تعذر تشغيل الملف المحمل'
              : 'تعذر تشغيل التلاوة، تأكد من اتصال الإنترنت',
        ),
      );
    }
  }

  Future<void> _downloadAllSurahs() async {
    if (isDownloadingAll) return;

    AppHaptics.tap(context);

    final confirmed = await _showConfirmDialog(
      title: 'تحميل المصحف',
      message:
          'سيتم تحميل السور المتاحة لهذا القارئ للاستماع بدون إنترنت.\nقد يستهلك ذلك مساحة وبيانات إنترنت.',
      confirmText: 'تحميل',
      isDestructive: false,
    );

    if (confirmed != true) return;

    final cancelToken = CancelToken();
    downloadAllCancelToken = cancelToken;

    setState(() {
      isDownloadingAll = true;
      downloadingAllText = 'جاري بدء التحميل...';
    });

    try {
      await RecitationDownloadService.downloadAllReciterSurahs(
        reciter: widget.reciter,
        cancelToken: cancelToken,
        onProgress: (current, total, surahName) {
          if (!mounted) return;

          setState(() {
            downloadingAllText = 'جاري تحميل $surahName ($current من $total)';
          });
        },
      );

      await _loadDownloadedSurahs();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        _successSnackBar(context, 'تم تحميل السور المتاحة لهذا القارئ'),
      );
    } on DioException catch (error) {
      if (!mounted) return;

      final isCancelled = CancelToken.isCancel(error);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        isCancelled
            ? _successSnackBar(context, 'تم إيقاف تحميل المصحف')
            : _errorSnackBar(context, 'تعذر إكمال التحميل، حاول مرة أخرى'),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        _errorSnackBar(context, 'تعذر إكمال التحميل، حاول مرة أخرى'),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isDownloadingAll = false;
        downloadingAllText = '';
        downloadAllCancelToken = null;
      });

      await _loadDownloadedSurahs();
    }
  }

  void _cancelDownloadAllSurahs() {
    AppHaptics.tap(context);

    if (downloadAllCancelToken != null &&
        !downloadAllCancelToken!.isCancelled) {
      downloadAllCancelToken!.cancel('تم إيقاف التحميل');
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final surfaceColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = scheme.onBackground;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: surfaceColor,
            surfaceTintColor: Colors.transparent,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              title,
              textAlign: TextAlign.right,
              style: AppTextStyles.headline(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: textColor),
            ),
            content: Text(
              message,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(
                context,
              ).copyWith(height: 1.6, color: textColor.withOpacity(0.72)),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor.withOpacity(0.65),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: Text(
                  confirmText,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDestructive ? Colors.redAccent : scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SnackBar _successSnackBar(BuildContext context, String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.primary,
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

  SnackBar _errorSnackBar(BuildContext context, String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;
    final surahs = filteredSurahs;

    final subtitleParts = [
      if (widget.reciter.qiratName.trim().isNotEmpty) widget.reciter.qiratName,
    ];

    final subtitle = subtitleParts.join(' - ');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
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
                        widget.reciter.name,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                    SizedBox(width: 38.w),
                  ],
                ),
              ),

              if (subtitle.trim().isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: textColor.withOpacity(0.55)),
                ),
              ],

              SizedBox(height: 14.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isDownloadingAll
                      ? _cancelDownloadAllSurahs
                      : _downloadAllSurahs,
                  icon: isDownloadingAll
                      ? Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.white,
                          size: 18.sp,
                        )
                      : const Icon(Icons.download_for_offline_rounded),
                  label: Text(
                    isDownloadingAll
                        ? 'إيقاف التحميل'
                        : 'تحميل السور المتاحة لهذا القارئ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDownloadingAll
                        ? Colors.redAccent
                        : primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                ),
              ),

              if (isDownloadingAll) ...[
                SizedBox(height: 6.h),
                Text(
                  downloadingAllText,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: textColor.withOpacity(0.65)),
                ),
              ],

              SizedBox(height: 10.h),

              Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xff171B26)
                      : primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.14)
                        : primary.withOpacity(0.16),
                    width: 0.9.w,
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'ابحث عن سورة',
                          hintStyle: AppTextStyles.caption(context).copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.45)
                                : textColor.withOpacity(0.45),
                          ),
                        ),
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: textColor),
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                      ),
                    ),
                    Icon(
                      Icons.search_rounded,
                      size: 18.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.65)
                          : textColor.withOpacity(0.65),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              Expanded(
                child: surahs.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد سور متاحة',
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: textColor.withOpacity(0.65)),
                        ),
                      )
                    : StreamBuilder<RecitationAudioState>(
                        stream:
                            RecitationAudioController.instance.audioStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;

                          return ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: surahs.length,
                            separatorBuilder: (_, __) => SizedBox(height: 7.h),
                            itemBuilder: (context, index) {
                              final surah = surahs[index];
                              final downloaded = downloadedSurahs[surah.number];
                              final savedProgress =
                                  savedProgressMap[surah.number];

                              final isCurrent = _isCurrentSurah(surah);

                              return _SurahTile(
                                surah: surah,
                                downloaded: downloaded,
                                savedProgress: savedProgress,
                                liveState: isCurrent ? state : null,
                                isCurrent: isCurrent,
                                onOpenPlayer: () {
                                  _openPlayer(surah);
                                },
                                onTogglePlayback: () {
                                  _toggleSurahPlayback(surah);
                                },
                              );
                            },
                          );
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

class _SurahTile extends StatelessWidget {
  final QuranSurahInfo surah;
  final DownloadedRecitationModel? downloaded;
  final RecitationSavedProgress? savedProgress;
  final RecitationAudioState? liveState;
  final bool isCurrent;
  final VoidCallback onOpenPlayer;
  final VoidCallback onTogglePlayback;

  const _SurahTile({
    required this.surah,
    required this.downloaded,
    required this.savedProgress,
    required this.liveState,
    required this.isCurrent,
    required this.onOpenPlayer,
    required this.onTogglePlayback,
  });

  bool get isDownloaded => downloaded != null;

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) return '$hours:$minutes:$seconds';

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    final livePosition = liveState?.position;
    final liveDuration = liveState?.duration;

    final displayPosition = livePosition ?? savedProgress?.position;
    final displayDuration = liveDuration ?? savedProgress?.duration;

    final hasProgress =
        displayPosition != null && displayPosition.inSeconds > 5;

    final durationHasValue =
        displayDuration != null && displayDuration.inMilliseconds > 0;

    double progressValue = 0;

    if (hasProgress && durationHasValue) {
      progressValue =
          (displayPosition.inMilliseconds / displayDuration.inMilliseconds)
              .clamp(0.0, 1.0);
    } else if (savedProgress != null) {
      progressValue = savedProgress!.progress;
    }

    final isPlaying = isCurrent && liveState?.playing == true;

    final statusText = isCurrent
        ? isPlaying
              ? 'يتم الاستماع الآن'
              : 'متوقفة مؤقتًا'
        : hasProgress
        ? 'آخر موضع: ${_formatDuration(displayPosition)}'
        : isDownloaded
        ? 'تم التحميل'
        : 'استماع مباشر';

    final statusColor = isCurrent
        ? primary
        : hasProgress
        ? textColor.withOpacity(0.72)
        : isDownloaded
        ? const Color(0xff21C58E)
        : textColor.withOpacity(0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: onOpenPlayer,
        child: Container(
          constraints: BoxConstraints(
            minHeight: progressValue > 0 ? 74.h : 62.h,
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: isCurrent
                  ? primary.withOpacity(0.55)
                  : textColor.withOpacity(0.08),
            ),
            color: isCurrent ? primary.withOpacity(0.06) : Colors.transparent,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 23.r,
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  surah.number.toString(),
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, color: primary),
                ),
              ),

              SizedBox(width: 9.w),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'سورة ${surah.name}',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, color: textColor),
                    ),

                    SizedBox(height: 3.h),

                    Text(
                      statusText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: statusColor,
                      ),
                    ),

                    if (progressValue > 0) ...[
                      SizedBox(height: 5.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 3.h,
                          backgroundColor: primary.withOpacity(0.10),
                          color: primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 6.w),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 34.w, minHeight: 34.h),
                onPressed: onTogglePlayback,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: primary,
                  size: 28.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
