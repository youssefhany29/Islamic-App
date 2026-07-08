import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../services/recitation_download_service.dart';
import '../services/recitation_listening_history_storage.dart';
import 'recitation_player_page.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class RecitationListeningHistoryPage extends StatefulWidget {
  const RecitationListeningHistoryPage({super.key});

  @override
  State<RecitationListeningHistoryPage> createState() =>
      _RecitationListeningHistoryPageState();
}

class _RecitationListeningHistoryPageState
    extends State<RecitationListeningHistoryPage> {
  bool isLoading = true;
  List<RecitationListeningHistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result = await RecitationListeningHistoryStorage.loadHistory();

    if (!mounted) return;

    setState(() {
      history = result;
      isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    AppHaptics.tap(context);

    final confirmed = await _showConfirmDialog();

    if (confirmed != true) return;

    await RecitationListeningHistoryStorage.clearHistory();
    await _loadHistory();
  }

  Future<bool?> _showConfirmDialog() {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final background = Theme.of(context).colorScheme.background;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'مسح سجل الاستماع',
              textAlign: TextAlign.right,
              style: AppTextStyles.headline(
                context,
              ).copyWith(fontWeight: FontWeight.w900, color: textColor),
            ),
            content: Text(
              'هل تريد مسح سجل الاستماع بالكامل؟',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.72),
                height: 1.6,
              ),
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
                  'مسح',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openHistoryItem(RecitationListeningHistoryItem item) async {
    AppHaptics.tap(context);

    final downloaded = await RecitationDownloadService.getDownload(
      reciterId: item.reciterId,
      source: item.reciterSource,
      surahNumber: item.surahNumber,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RecitationPlayerPage(
              reciterId: item.reciterId,
              reciterName: item.reciterName,
              reciterSource: item.reciterSource,
              mp3QuranServerUrl: item.mp3QuranServerUrl,
              surahNumber: item.surahNumber,
              surahName: item.surahName,
              initialAudioUrl: downloaded?.audioUrl ?? item.audioUrl,
              localFilePath: downloaded?.localFilePath,
              startPosition: Duration(seconds: item.positionSeconds),
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) => _loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

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
                        'سجل الاستماع',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.headline(context).copyWith(
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
                      onPressed: history.isEmpty ? null : _clearHistory,
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        size: 21.sp,
                        color: history.isEmpty
                            ? textColor.withOpacity(0.25)
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : history.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد سجل استماع بعد',
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: textColor.withOpacity(0.65)),
                        ),
                      )
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: history.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
                          itemBuilder: (context, index) {
                            final item = history[index];

                            return _HistoryTile(
                              item: item,
                              onTap: () {
                                _openHistoryItem(item);
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

class _HistoryTile extends StatelessWidget {
  final RecitationListeningHistoryItem item;
  final VoidCallback onTap;

  const _HistoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    final timeText = RecitationListeningHistoryStorage.formatHistoryTime(
      item.listenedAtMs,
    );

    final listenedText = RecitationListeningHistoryStorage.formatShortDuration(
      item.listenedSeconds,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 72.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: textColor.withOpacity(0.08)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 21.r,
                backgroundColor: primary.withOpacity(0.12),
                child: Icon(Icons.history_rounded, color: primary, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'سورة ${item.surahName}',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900, color: textColor),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${item.reciterName} • $listenedText • $timeText',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill_rounded, color: primary, size: 25.sp),
            ],
          ),
        ),
      ),
    );
  }
}
