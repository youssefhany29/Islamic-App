part of 'hadith_memory_analytics_page.dart';

class _MemoryItemsCard extends StatelessWidget {
  const _MemoryItemsCard({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.items,
    required this.icon,
    required this.color,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<HadithMemoryItemStateModel> items;
  final IconData icon;
  final Color color;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _HeaderRow(
            icon: icon,
            color: color,
            title: title,
            subtitle: subtitle,
          ),
          if (actionText != null && onActionTap != null) ...[
            SizedBox(height: m.large ? 10 : 10.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActionTap,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: m.large ? 11 : 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(m.large ? 14 : 14.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: m.large ? 18 : 18.sp),
                    SizedBox(width: m.large ? 6 : 6.w),
                    Text(
                      actionText!,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: m.bodyTextSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: m.large ? 11 : 10.h),
          if (items.isEmpty)
            _ArabicText(
              emptyText,
              fontSize: m.bodyTextSize,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.surface.withOpacity(0.62),
              height: 1.55,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: m.large ? 8 : 8.h),
                child: _MemoryStateTile(item: item, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemoryStateTile extends StatelessWidget {
  const _MemoryStateTile({required this.item, required this.color});

  final HadithMemoryItemStateModel item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.tilePadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(m.tileRadius),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: m.tileIconBox,
              height: m.tileIconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(m.large ? 13 : 13.r),
              ),
              child: Text(
                item.memoryStrength.toStringAsFixed(0),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: m.smallTextSize,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            SizedBox(width: m.large ? 9 : 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ArabicText(
                    item.itemTitle,
                    fontSize: m.tileTitleSize,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
                    maxLines: 2,
                  ),
                  SizedBox(height: m.large ? 3 : 2.h),
                  _ArabicText(
                    '${item.categoryTitle} • ${item.level.label} • المراجعة: ${item.reviewDateText}',
                    fontSize: m.tileSubtitleSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.surface.withOpacity(0.62),
                    height: 1.45,
                    maxLines: 2,
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

class _RecentAttemptsCard extends StatelessWidget {
  const _RecentAttemptsCard({required this.attempts});

  final List<HadithMemoryAttemptModel> attempts;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _HeaderRow(
            icon: Icons.history_rounded,
            color: theme.colorScheme.primary,
            title: 'آخر محاولات الحفظ',
            subtitle:
                'آخر التقييمات التي سجّلتها بعد القراءة أو التدريب أو الاختبار.',
          ),
          SizedBox(height: m.large ? 11 : 10.h),
          if (attempts.isEmpty)
            _ArabicText(
              'لسه مفيش محاولات حفظ مسجلة.',
              fontSize: m.bodyTextSize,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.surface.withOpacity(0.62),
            )
          else
            ...attempts.map(
              (attempt) => Padding(
                padding: EdgeInsets.only(bottom: m.large ? 8 : 8.h),
                child: _AttemptTile(attempt: attempt),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

  final HadithMemoryAttemptModel attempt;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);
    final color = attempt.rating == HadithMemoryRating.mastered
        ? const Color(0xff21C58E)
        : attempt.rating == HadithMemoryRating.partial
        ? const Color(0xffF59E0B)
        : const Color(0xffEF4444);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.tilePadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(m.tileRadius),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: m.tileIconBox,
              height: m.tileIconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(m.large ? 13 : 12.r),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: color,
                size: m.large ? 19 : 19.sp,
              ),
            ),
            SizedBox(width: m.large ? 9 : 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ArabicText(
                    attempt.itemTitle,
                    fontSize: m.tileTitleSize,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
                    maxLines: 2,
                  ),
                  SizedBox(height: m.large ? 3 : 2.h),
                  _ArabicText(
                    '${attempt.categoryTitle} • ${attempt.rating.label} • ${attempt.practiceMode.label}',
                    fontSize: m.tileSubtitleSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.surface.withOpacity(0.62),
                    height: 1.45,
                    maxLines: 2,
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

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.onRebuildAnalysis,
    required this.onResetAnalysis,
  });

  final Future<void> Function() onRebuildAnalysis;
  final VoidCallback onResetAnalysis;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);

    if (m.large) {
      return Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(child: _RebuildButton(onTap: onRebuildAnalysis)),
          SizedBox(width: m.gap),
          Expanded(child: _ResetAnalysisButton(onTap: onResetAnalysis)),
        ],
      );
    }

    return Column(
      children: [
        _RebuildButton(onTap: onRebuildAnalysis),
        SizedBox(height: 8.h),
        _ResetAnalysisButton(onTap: onResetAnalysis),
      ],
    );
  }
}

class _RebuildButton extends StatelessWidget {
  const _RebuildButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.35),
            ),
            padding: EdgeInsets.symmetric(vertical: m.large ? 12 : 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(m.large ? 15 : 14.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: m.large ? 18 : 18.sp),
              SizedBox(width: m.large ? 7 : 6.w),
              Flexible(
                child: Text(
                  'إعادة بناء التحليل من المحاولات السابقة',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: m.bodyTextSize,
                    fontWeight: FontWeight.w800,
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

class _ResetAnalysisButton extends StatelessWidget {
  const _ResetAnalysisButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.35),
            ),
            padding: EdgeInsets.symmetric(vertical: m.large ? 12 : 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(m.large ? 15 : 14.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_sweep_rounded, size: m.large ? 18 : 18.sp),
              SizedBox(width: m.large ? 7 : 6.w),
              Flexible(
                child: Text(
                  'إعادة ضبط خطة الحفظ',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: m.bodyTextSize,
                    fontWeight: FontWeight.w800,
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

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(m.cardRadius),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.10 : 0.025,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Directionality(textDirection: TextDirection.rtl, child: child),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: m.headerIconBox,
            height: m.headerIconBox,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(m.large ? 14 : 14.r),
            ),
            child: Icon(icon, color: color, size: m.headerIconSize),
          ),
          SizedBox(width: m.large ? 10 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ArabicText(
                  title,
                  fontSize: m.headerTitleSize,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  maxLines: 1,
                ),
                SizedBox(height: m.large ? 3 : 3.h),
                _ArabicText(
                  subtitle,
                  fontSize: m.headerSubtitleSize,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.surface.withOpacity(0.62),
                  height: 1.5,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteHeaderRow extends StatelessWidget {
  const _WhiteHeaderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final m = _AnalyticsMetrics.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: m.large ? 46 : 44.w,
            height: m.large ? 46 : 44.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(m.large ? 15 : 15.r),
            ),
            child: Icon(icon, color: Colors.white, size: m.large ? 24 : 24.sp),
          ),
          SizedBox(width: m.large ? 11 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ArabicText(
                  title,
                  fontSize: m.large ? 17 : 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  maxLines: 1,
                ),
                SizedBox(height: m.large ? 4 : 3.h),
                _ArabicText(
                  subtitle,
                  fontSize: m.large ? 12 : 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.80),
                  height: 1.5,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArabicText extends StatelessWidget {
  const _ArabicText(
    this.text, {
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    this.height,
    this.maxLines,
    this.textAlign = TextAlign.right,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double? height;
  final int? maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: textAlign,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        softWrap: true,
        maxLines: maxLines,
        overflow: maxLines == null
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
