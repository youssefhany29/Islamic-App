part of 'recitation_player_page.dart';

class _SleepTimerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SleepTimerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RecitationSleepTimerState>(
      valueListenable: RecitationSleepTimerService.instance.stateNotifier,
      builder: (context, state, _) {
        return Material(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: onTap,
            child: SizedBox(
              height: 34.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.bedtime_rounded,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      state.active ? 'النوم ${state.remainingText}' : 'النوم',
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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

class _DownloadButton extends StatelessWidget {
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String title;

    if (isDownloaded) {
      title = 'محملة';
    } else if (isDownloading) {
      title = '${(progress * 100).clamp(0, 100).toInt()}%';
    } else {
      title = 'تحميل';
    }

    return Material(
      color: Colors.white.withOpacity(isDownloaded ? 0.22 : 0.14),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: isDownloaded ? null : onTap,
        child: SizedBox(
          height: 34.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                if (isDownloading)
                  SizedBox(
                    width: 13.w,
                    height: 13.w,
                    child: CircularProgressIndicator(
                      value: progress <= 0 ? null : progress,
                      strokeWidth: 2.w,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.22),
                    ),
                  )
                else
                  Icon(
                    isDownloaded
                        ? Icons.download_done_rounded
                        : Icons.download_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                SizedBox(width: 5.w),
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(isFavorite ? 0.22 : 0.14),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: SizedBox(
          width: 34.w,
          height: 34.h,
          child: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFavorite ? const Color(0xffffb300) : Colors.white,
            size: 18.sp,
          ),
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  final ValueChanged<Duration> onSelect;
  final VoidCallback onCancel;

  const _SleepTimerSheet({required this.onSelect, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.background;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 22.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Center(
            child: Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'مؤقت النوم',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.body(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: textColor),
          ),
          SizedBox(height: 6.h),
          Text(
            'اختر مدة، وسيتم إيقاف التلاوة تلقائيًا.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: textColor.withOpacity(0.62)),
          ),
          SizedBox(height: 14.h),
          _TimerOption(
            title: 'بعد 10 دقائق',
            icon: Icons.timer_10_rounded,
            color: primary,
            onTap: () => onSelect(const Duration(minutes: 10)),
          ),
          SizedBox(height: 8.h),
          _TimerOption(
            title: 'بعد 20 دقيقة',
            icon: Icons.timer_rounded,
            color: primary,
            onTap: () => onSelect(const Duration(minutes: 20)),
          ),
          SizedBox(height: 8.h),
          _TimerOption(
            title: 'بعد 30 دقيقة',
            icon: Icons.more_time_rounded,
            color: primary,
            onTap: () => onSelect(const Duration(minutes: 30)),
          ),
          SizedBox(height: 8.h),
          _TimerOption(
            title: 'إلغاء المؤقت',
            icon: Icons.close_rounded,
            color: Colors.redAccent,
            onTap: onCancel,
          ),
        ],
      ),
    );
  }
}

class _TimerOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimerOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: color, size: 19.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final String Function(Duration duration) formatDuration;
  final ValueChanged<Duration> onSeek;

  const _ProgressSection({
    required this.position,
    required this.duration,
    required this.formatDuration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();

    final currentValue = position.inMilliseconds.clamp(0, maxValue.toInt());

    return Column(
      children: [
        Slider(
          value: currentValue.toDouble(),
          min: 0,
          max: maxValue,
          activeColor: Colors.white,
          inactiveColor: Colors.white.withOpacity(0.25),
          onChanged: duration.inMilliseconds <= 0
              ? null
              : (value) {
                  onSeek(Duration(milliseconds: value.toInt()));
                },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                duration.inMilliseconds <= 0
                    ? '--:--'
                    : formatDuration(duration),
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: Colors.white.withOpacity(0.75)),
              ),
              Text(
                formatDuration(position),
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: Colors.white.withOpacity(0.75)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
