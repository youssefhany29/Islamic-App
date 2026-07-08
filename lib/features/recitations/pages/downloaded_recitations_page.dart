import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/downloaded_recitation_model.dart';
import '../services/recitation_audio_controller.dart';
import '../services/recitation_download_service.dart';
import '../services/recitation_progress_storage.dart';
import 'recitation_player_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class DownloadedRecitationsPage extends StatefulWidget {
  const DownloadedRecitationsPage({super.key});

  @override
  State<DownloadedRecitationsPage> createState() =>
      _DownloadedRecitationsPageState();
}

class _DownloadedRecitationsPageState extends State<DownloadedRecitationsPage> {
  List<DownloadedRecitationModel> downloads = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    final loadedDownloads = await RecitationDownloadService.getAllDownloads();

    if (!mounted) return;

    setState(() {
      downloads = loadedDownloads;
      isLoading = false;
    });
  }

  Map<String, List<DownloadedRecitationModel>> get groupedDownloads {
    final grouped = <String, List<DownloadedRecitationModel>>{};

    for (final download in downloads) {
      final key = '${download.reciterSource.name}_${download.reciterId}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(download);
    }

    return grouped;
  }

  List<List<DownloadedRecitationModel>> get filteredGroups {
    final groups = groupedDownloads.values.toList();
    final text = searchText.trim();

    if (text.isEmpty) return groups;

    return groups.where((reciterDownloads) {
      final first = reciterDownloads.first;
      return first.reciterName.contains(text);
    }).toList();
  }

  Future<void> _deleteAllDownloads() async {
    AppHaptics.tap(context);

    final confirmed = await _showConfirmDialog(
      title: 'حذف كل التنزيلات',
      message: 'هل تريد حذف كل التلاوات المحملة؟',
      confirmText: 'حذف',
    );

    if (confirmed != true) return;

    await RecitationDownloadService.deleteAllDownloads();
    await _loadDownloads();
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.headline(
              context,
            ).copyWith(fontWeight: FontWeight.w800, color: textColor),
          ),
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(
              context,
            ).copyWith(height: 1.6, color: textColor.withOpacity(0.85)),
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
                  color: textColor.withOpacity(0.7),
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
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openReciterDownloads(List<DownloadedRecitationModel> reciterDownloads) {
    AppHaptics.tap(context);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DownloadedReciterSurahsPage(downloads: reciterDownloads),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      _loadDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;
    final groups = filteredGroups;

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
                        'تنزيلاتي',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.headline(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: downloads.isEmpty ? null : _deleteAllDownloads,
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: downloads.isEmpty
                            ? textColor.withOpacity(0.25)
                            : Colors.redAccent,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              _SearchBox(
                controller: searchController,
                hintText: 'ابحث في تنزيلاتك',
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : downloads.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد تلاوات محملة بعد',
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: textColor.withOpacity(0.65)),
                        ),
                      )
                    : groups.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج',
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: textColor.withOpacity(0.65)),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final reciterDownloads = groups[index];
                          final first = reciterDownloads.first;

                          final totalBytes = reciterDownloads.fold<int>(
                            0,
                            (sum, item) => sum + item.fileSizeBytes,
                          );

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () {
                                _openReciterDownloads(reciterDownloads);
                              },
                              child: Container(
                                height: 66.h,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: textColor.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    CircleAvatar(
                                      radius: 22.r,
                                      backgroundColor: primary.withOpacity(
                                        0.12,
                                      ),
                                      child: Icon(
                                        Icons.download_done_rounded,
                                        color: primary,
                                        size: 22.sp,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            first.reciterName,
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTextStyles.caption(
                                                  context,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            '${reciterDownloads.length} سورة محملة • ${RecitationDownloadService.formatSize(totalBytes)}',
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTextStyles.caption(
                                                  context,
                                                ).copyWith(
                                                  color: textColor.withOpacity(
                                                    0.55,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16.sp,
                                      color: textColor.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

class DownloadedReciterSurahsPage extends StatefulWidget {
  final List<DownloadedRecitationModel> downloads;

  const DownloadedReciterSurahsPage({super.key, required this.downloads});

  @override
  State<DownloadedReciterSurahsPage> createState() =>
      _DownloadedReciterSurahsPageState();
}

class _DownloadedReciterSurahsPageState
    extends State<DownloadedReciterSurahsPage> {
  late List<DownloadedRecitationModel> downloads;
  final TextEditingController searchController = TextEditingController();
  final Map<int, RecitationSavedProgress> savedProgressMap = {};

  String searchText = '';

  @override
  void initState() {
    super.initState();

    downloads = [...widget.downloads]
      ..sort((a, b) => a.surahNumber.compareTo(b.surahNumber));

    _loadSavedProgress();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DownloadedRecitationModel> get filteredDownloads {
    final text = searchText.trim();

    if (text.isEmpty) return downloads;

    return downloads.where((download) {
      return download.surahName.contains(text) ||
          download.surahNumber.toString() == text;
    }).toList();
  }

  Future<void> _loadSavedProgress() async {
    final Map<int, RecitationSavedProgress> result = {};

    for (final download in downloads) {
      final progress = await RecitationProgressStorage.getSavedProgressInfo(
        reciterId: download.reciterId,
        reciterSource: download.reciterSource,
        surahNumber: download.surahNumber,
      );

      if (progress.hasProgress || progress.duration.inSeconds > 0) {
        result[download.surahNumber] = progress;
      }
    }

    if (!mounted) return;

    setState(() {
      savedProgressMap
        ..clear()
        ..addAll(result);
    });
  }

  bool _isCurrentDownload(DownloadedRecitationModel download) {
    final currentInfo = RecitationAudioController.instance.currentInfo;

    if (currentInfo == null) return false;

    return currentInfo.reciterId == download.reciterId &&
        currentInfo.reciterSource == download.reciterSource &&
        currentInfo.surahNumber == download.surahNumber;
  }

  Duration _savedStartPosition(DownloadedRecitationModel download) {
    return savedProgressMap[download.surahNumber]?.position ?? Duration.zero;
  }

  Future<void> _toggleDownloadPlayback(
    DownloadedRecitationModel download,
  ) async {
    AppHaptics.tap(context);

    final audioController = RecitationAudioController.instance;

    if (_isCurrentDownload(download)) {
      await audioController.togglePlayPause();
      await _loadSavedProgress();
      return;
    }

    try {
      await audioController.playRecitation(
        reciterId: download.reciterId,
        reciterName: download.reciterName,
        reciterSource: download.reciterSource,
        mp3QuranServerUrl: download.mp3QuranServerUrl,
        surahNumber: download.surahNumber,
        surahName: download.surahName,
        startPosition: _savedStartPosition(download),
        initialAudioUrl: download.audioUrl,
        localFilePath: download.localFilePath,
      );

      await _loadSavedProgress();
    } catch (error) {
      debugPrint('❌ Failed to play downloaded recitation: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_errorSnackBar('تعذر تشغيل التلاوة المحملة'));
    }
  }

  Future<void> _deleteDownload(DownloadedRecitationModel download) async {
    AppHaptics.tap(context);

    final confirmed = await _showConfirmDialog(
      title: 'حذف التلاوة',
      message: 'هل تريد حذف سورة ${download.surahName} من التنزيلات؟',
      confirmText: 'حذف',
    );

    if (confirmed != true) return;

    await RecitationDownloadService.deleteDownload(download);

    setState(() {
      downloads.removeWhere((item) => item.uniqueKey == download.uniqueKey);
      savedProgressMap.remove(download.surahNumber);
    });

    if (downloads.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.headline(
              context,
            ).copyWith(fontWeight: FontWeight.w800, color: textColor),
          ),
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(
              context,
            ).copyWith(height: 1.6, color: textColor.withOpacity(0.85)),
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
                  color: textColor.withOpacity(0.7),
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
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  SnackBar _errorSnackBar(String message) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      elevation: 0,
      margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(
          context,
        ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  void _openPlayer(DownloadedRecitationModel download) {
    AppHaptics.tap(context);

    final audioController = RecitationAudioController.instance;
    final isCurrent = _isCurrentDownload(download);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecitationPlayerPage(
              reciterId: download.reciterId,
              reciterName: download.reciterName,
              reciterSource: download.reciterSource,
              mp3QuranServerUrl: download.mp3QuranServerUrl,
              surahNumber: download.surahNumber,
              surahName: download.surahName,
              initialAudioUrl: download.audioUrl,
              localFilePath: download.localFilePath,
              startPosition: isCurrent
                  ? audioController.player.position
                  : _savedStartPosition(download),
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadSavedProgress());
  }

  @override
  Widget build(BuildContext context) {
    final first = downloads.first;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;
    final visibleDownloads = filteredDownloads;

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
                        first.reciterName,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 38.w),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              _SearchBox(
                controller: searchController,
                hintText: 'ابحث عن سورة',
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: visibleDownloads.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج',
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
                            itemCount: visibleDownloads.length,
                            separatorBuilder: (_, __) => SizedBox(height: 8.h),
                            itemBuilder: (context, index) {
                              final download = visibleDownloads[index];
                              final savedProgress =
                                  savedProgressMap[download.surahNumber];
                              final isCurrent = _isCurrentDownload(download);

                              return _DownloadedSurahTile(
                                download: download,
                                savedProgress: savedProgress,
                                liveState: isCurrent ? state : null,
                                isCurrent: isCurrent,
                                onOpenPlayer: () {
                                  _openPlayer(download);
                                },
                                onTogglePlayback: () {
                                  _toggleDownloadPlayback(download);
                                },
                                onDelete: () {
                                  _deleteDownload(download);
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff171B26) : primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
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
              controller: controller,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppTextStyles.caption(context).copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.45)
                      : textColor.withOpacity(0.45),
                ),
              ),
              style: AppTextStyles.caption(context).copyWith(color: textColor),
              onChanged: onChanged,
            ),
          ),
          Icon(
            Icons.search_rounded,
            size: 18.sp,
            color: isDark
                ? Colors.white.withOpacity(0.65)
                : textColor.withOpacity(0.65),
          ),
        ],
      ),
    );
  }
}

class _DownloadedSurahTile extends StatelessWidget {
  final DownloadedRecitationModel download;
  final RecitationSavedProgress? savedProgress;
  final RecitationAudioState? liveState;
  final bool isCurrent;
  final VoidCallback onOpenPlayer;
  final VoidCallback onTogglePlayback;
  final VoidCallback onDelete;

  const _DownloadedSurahTile({
    required this.download,
    required this.savedProgress,
    required this.liveState,
    required this.isCurrent,
    required this.onOpenPlayer,
    required this.onTogglePlayback,
    required this.onDelete,
  });

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
        : 'متاحة بدون إنترنت • ${RecitationDownloadService.formatSize(download.fileSizeBytes)}';

    final statusColor = isCurrent
        ? primary
        : hasProgress
        ? textColor.withOpacity(0.72)
        : const Color(0xff21C58E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onOpenPlayer,
        child: Container(
          constraints: BoxConstraints(minHeight: 82.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isCurrent
                  ? primary.withOpacity(0.55)
                  : textColor.withOpacity(0.08),
            ),
            color: isCurrent ? primary.withOpacity(0.06) : Colors.transparent,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: primary.withOpacity(0.12),
                child: Text(
                  download.surahNumber.toString(),
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: primary),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'سورة ${download.surahName}',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, color: textColor),
                    ),
                    SizedBox(height: 4.h),
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
                          minHeight: 3.5.h,
                          backgroundColor: primary.withOpacity(0.10),
                          color: primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onTogglePlayback,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: primary,
                  size: 27.sp,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 21.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
