part of 'zekr_item_details_page.dart';

class _CustomActionsCard extends StatelessWidget {
  const _CustomActionsCard({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.34),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: Icon(Icons.edit_rounded, size: 17.sp),
                label: Text(
                  'تعديل',
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.36),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 17.sp),
                label: Text(
                  'حذف',
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withOpacity(0.42),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.categoryTitle,
    required this.isCompleted,
  });

  final String title;
  final String categoryTitle;
  final bool isCompleted;

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = _isLargeScreen(context);
    final double radius = isLargeScreen ? 24 : 20.r;
    final double padding = isLargeScreen ? 18 : 14.w;
    final double iconBox = isLargeScreen ? 46 : 42.w;
    final double iconSize = isLargeScreen ? 23 : 22.sp;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xff21C58E)
            : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: isLargeScreen ? 72 : 60.h),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: iconBox + (isLargeScreen ? 18 : 16.w),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.pageHeader(
                            context,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 5 : 3.h),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          isCompleted
                              ? 'تم إنجاز هذا الذكر اليوم'
                              : categoryTitle,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          locale: const Locale('ar'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardSubtitle(
                            context,
                            color: Colors.white.withOpacity(0.78),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: iconBox,
                  height: iconBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(
                      isLargeScreen ? 16 : 14.r,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.menu_book_rounded,
                    color: Colors.white,
                    size: iconSize,
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

class _ZekrFullTextCard extends StatelessWidget {
  const _ZekrFullTextCard({required this.item, required this.reference});

  final ZekrItemModel item;
  final String? reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            softWrap: true,
            locale: const Locale('ar'),
            style: AppTypography.detailContent(
              context,
              color: theme.colorScheme.surface,
              height: item.isQuranVerse ? 1.95 : 1.75,
            ),
          ),
          if (reference != null && reference!.trim().isNotEmpty) ...[
            SizedBox(height: 14.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(
                    isDark ? 0.18 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  reference!,
                  textAlign: TextAlign.left,
                  locale: const Locale('ar'),
                  style: AppTypography.metadata(
                    context,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.source, required this.benefit});

  final String? source;
  final String? benefit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (source != null) ...[
            _InfoLine(
              icon: Icons.book_outlined,
              title: 'المصدر',
              text: source!,
            ),
          ],
          if (source != null && benefit != null) SizedBox(height: 10.h),
          if (benefit != null) ...[
            _InfoLine(
              icon: Icons.favorite_border_rounded,
              title: 'الفائدة',
              text: benefit!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 13.5.sp),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: AppTypography.metadata(
                    context,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  text,
                  textAlign: TextAlign.right,
                  locale: const Locale('ar'),
                  style: AppTypography.cardSubtitle(
                    context,
                    color: theme.colorScheme.surface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.item,
    required this.counter,
    required this.total,
    required this.progress,
    required this.isCompleted,
    required this.onIncrement,
    required this.onMarkCompleted,
    required this.onUnmarkCompleted,
  });

  final ZekrItemModel item;
  final int counter;
  final int total;
  final double progress;
  final bool isCompleted;
  final VoidCallback onIncrement;
  final VoidCallback onMarkCompleted;
  final VoidCallback onUnmarkCompleted;

  bool _isLargeScreen(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 ||
        (size.width >= 700 && size.height >= 500);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color doneColor = const Color(0xff21C58E);
    final bool isLargeScreen = _isLargeScreen(context);

    final double cardPadding = isLargeScreen ? 16 : 12.w;
    final double radius = isLargeScreen ? 22 : 20.r;
    final double iconBox = isLargeScreen ? 42 : 38.w;
    final double iconSize = isLargeScreen ? 20 : 17.sp;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isCompleted
                ? doneColor
                : theme.colorScheme.outline.withOpacity(0.36),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.10 : 0.035,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: isLargeScreen ? 48 : 42.h),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isLargeScreen ? 112 : 104.w,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Container(
                            width: iconBox,
                            height: iconBox,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  (isCompleted
                                          ? doneColor
                                          : theme.colorScheme.primary)
                                      .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(
                                isLargeScreen ? 15 : 14.r,
                              ),
                            ),
                            child: Icon(
                              Icons.repeat_rounded,
                              color: isCompleted
                                  ? doneColor
                                  : theme.colorScheme.primary,
                              size: iconSize,
                            ),
                          ),
                          SizedBox(width: isLargeScreen ? 10 : 8.w),
                          Flexible(
                            child: Text(
                              'عدد التكرار',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle(
                                context,
                                color: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 11 : 10.w,
                        vertical: isLargeScreen ? 6 : 5.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isCompleted
                                    ? doneColor
                                    : theme.colorScheme.primary)
                                .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(
                          isLargeScreen ? 30 : 30.r,
                        ),
                      ),
                      child: Text(
                        '$counter / $total',
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: isCompleted
                              ? doneColor
                              : theme.colorScheme.primary,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLargeScreen ? 12 : 9.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(100.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: isLargeScreen ? 8 : 7.h,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.20),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? doneColor : theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: isLargeScreen ? 14 : 12.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool stackButtons = constraints.maxWidth < 360;

                final Widget completeButton = OutlinedButton(
                  onPressed: isCompleted ? onUnmarkCompleted : onMarkCompleted,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCompleted
                        ? doneColor
                        : theme.colorScheme.primary,
                    side: BorderSide(
                      color: isCompleted
                          ? doneColor
                          : theme.colorScheme.primary,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isLargeScreen ? 12 : 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isLargeScreen ? 15 : 14.r,
                      ),
                    ),
                  ),
                  child: Text(
                    isCompleted ? 'إلغاء التمام' : 'تم الذكر',
                    textDirection: TextDirection.rtl,
                    style: AppTypography.button(context),
                  ),
                );

                final Widget incrementButton = ElevatedButton(
                  onPressed: isCompleted ? null : onIncrement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: doneColor.withOpacity(0.18),
                    disabledForegroundColor: doneColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      vertical: isLargeScreen ? 12 : 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isLargeScreen ? 15 : 14.r,
                      ),
                    ),
                  ),
                  child: Text(
                    isCompleted ? item.completedLabel : item.actionButtonLabel,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.button(context),
                  ),
                );

                if (stackButtons) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: incrementButton),
                      SizedBox(height: 8.h),
                      SizedBox(width: double.infinity, child: completeButton),
                    ],
                  );
                }

                return Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(child: incrementButton),
                    SizedBox(width: isLargeScreen ? 10 : 10.w),
                    Expanded(child: completeButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
