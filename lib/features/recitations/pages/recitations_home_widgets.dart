part of 'recitations_home_page.dart';

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenHistory;
  final bool hasFavorites;
  final bool hasHistory;

  const _Header({
    required this.title,
    required this.onBack,
    required this.onOpenFavorites,
    required this.onOpenHistory,
    required this.hasFavorites,
    required this.hasHistory,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: SizedBox(
        height: 38.h,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17.sp,
                  color: textColor,
                ),
              ),
            ),

            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: textColor),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    icon: hasHistory
                        ? Icons.history_rounded
                        : Icons.history_toggle_off_rounded,
                    active: hasHistory,
                    onTap: onOpenHistory,
                  ),
                  SizedBox(width: 4.w),
                  _HeaderIconButton(
                    icon: hasFavorites
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    active: hasFavorites,
                    activeColor: const Color(0xffffb300),
                    onTap: onOpenFavorites,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: active ? primary.withOpacity(0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: 32.w,
          height: 32.h,
          child: Icon(
            icon,
            size: 19.sp,
            color: active
                ? (activeColor ?? primary)
                : textColor.withOpacity(0.48),
          ),
        ),
      ),
    );
  }
}

class _ContinueListeningCard extends StatelessWidget {
  final Map<String, dynamic>? lastRecitation;
  final VoidCallback onTap;
  final VoidCallback onTogglePlayPause;

  const _ContinueListeningCard({
    required this.lastRecitation,
    required this.onTap,
    required this.onTogglePlayPause,
  });

  static String _formatSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) return '$hours:$minutes:$secs';
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final currentInfo = RecitationAudioController.instance.currentInfo;
    const innerDarkColor = Color(0xff171B26);

    return StreamBuilder<RecitationAudioState>(
      stream: RecitationAudioController.instance.audioStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isLive = currentInfo != null;

        final surahName = isLive
            ? currentInfo.surahName
            : lastRecitation == null
            ? null
            : lastRecitation!['surahName'].toString();

        final reciterName = isLive
            ? currentInfo.reciterName
            : lastRecitation == null
            ? null
            : lastRecitation!['reciterName'].toString();

        final positionSeconds = isLive
            ? (state?.position.inSeconds ??
                  RecitationAudioController.instance.player.position.inSeconds)
            : lastRecitation == null
            ? 0
            : lastRecitation!['positionSeconds'] as int;

        final durationSeconds = isLive
            ? (state?.duration.inSeconds ??
                  RecitationAudioController
                      .instance
                      .player
                      .duration
                      ?.inSeconds ??
                  0)
            : lastRecitation == null
            ? 0
            : lastRecitation!['durationSeconds'] as int;

        final lastPositionText = positionSeconds > 5
            ? '${isLive ? 'الآن' : 'آخر موضع'}: ${_formatSeconds(positionSeconds)}'
            : 'ابدأ الاستماع الآن';

        final connectionWarning = state?.connectionWarning == true;
        final isOffline = currentInfo?.isOffline == true;

        double progress = 0;

        if (durationSeconds > 0) {
          progress = (positionSeconds / durationSeconds).clamp(0.0, 1.0);
        }

        return Material(
          color: primary,
          borderRadius: BorderRadius.circular(18.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 92.h),
              padding: EdgeInsets.all(10.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: innerDarkColor,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 0.8.w,
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    GestureDetector(
                      onTap: isLive ? onTogglePlayPause : onTap,
                      child: CircleAvatar(
                        radius: 20.r,
                        backgroundColor: Colors.white,
                        child: Icon(
                          state?.playing == true
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: primary,
                          size: 26.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: AppTextStyles.caption(
                                context,
                              ).copyWith(color: Colors.white),
                              children: [
                                const TextSpan(
                                  text: 'تابع الاستماع',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                TextSpan(
                                  text: surahName == null ? '' : '  سورة ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.84),
                                  ),
                                ),
                                if (surahName != null)
                                  TextSpan(
                                    text: surahName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.78),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            reciterName == null
                                ? 'لا يوجد استماع محفوظ'
                                : '$reciterName • $lastPositionText',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isLive
                                ? isOffline
                                      ? 'متاحة بدون إنترنت'
                                      : connectionWarning
                                      ? 'الاتصال غير مستقر، تأكد من الشبكة'
                                      : 'تشغيل مباشر'
                                : 'آخر استماع محفوظ',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: connectionWarning
                                  ? Colors.orangeAccent
                                  : Colors.white.withOpacity(0.58),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3.5.h,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool muted;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: muted ? primary.withOpacity(0.58) : primary,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: onTap,
        child: SizedBox(
          height: 52.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19.sp),
              SizedBox(height: 3.h),
              Text(
                title,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final ReciterModel reciter;
  final int downloadedCount;
  final bool isFavorite;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _ReciterTile({
    required this.reciter,
    required this.downloadedCount,
    required this.isFavorite,
    required this.isCurrent,
    required this.isLast,
    required this.onTap,
    required this.onToggleFavorite,
  });

  String get subtitle {
    final parts = [
      if (reciter.qiratName.trim().isNotEmpty) reciter.qiratName,
      if (reciter.translatedName.trim().isNotEmpty) reciter.translatedName,
    ];

    if (parts.isEmpty) return 'تلاوة القرآن الكريم';

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    final badgeText = isCurrent
        ? 'يتم الاستماع الآن'
        : downloadedCount > 0
        ? '$downloadedCount سورة محملة'
        : isLast
        ? 'آخر استماع'
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 62.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isCurrent
                  ? primary.withOpacity(0.45)
                  : textColor.withOpacity(0.08),
            ),
            color: isCurrent ? primary.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: primary.withOpacity(0.12),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      reciter.name,
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
                      subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: textColor.withOpacity(0.55)),
                    ),
                    if (badgeText.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? primary
                                : const Color(0xff21C58E).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            badgeText,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w800,
                              color: isCurrent
                                  ? Colors.white
                                  : const Color(0xff21C58E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorite
                      ? const Color(0xffffb300)
                      : textColor.withOpacity(0.42),
                  size: 22.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorView({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: Theme.of(context).colorScheme.onBackground),
          ),
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String text;

  const _EmptyView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: AppTextStyles.caption(context).copyWith(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.65),
        ),
      ),
    );
  }
}
