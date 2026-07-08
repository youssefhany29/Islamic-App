part of 'daily_wird_page.dart';

class _NoActiveWirdCard extends StatelessWidget {
  final VoidCallback onCreatePlan;
  final bool large;

  const _NoActiveWirdCard({required this.onCreatePlan, this.large = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(large ? 16 : 18.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(large ? 20 : 20.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: large ? 38 : 42.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: large ? 10 : 10.h),
          Text(
            'لا توجد أوراد حالية',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: large ? 13 : 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: large ? 5 : 6.h),
          Text(
            'أنشئ وردًا جديدًا مثل ورد رمضان أو ختمة يومية.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: large ? 9.5 : 10.sp,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: large ? 12 : 12.h),
          SizedBox(
            height: large ? 38 : 38.h,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCreatePlan,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'إنشاء ورد',
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: MediaQuery.sizeOf(context).width >= 600
                      ? 10.5
                      : 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveWirdCard extends StatelessWidget {
  final QuranDailyWird wird;
  final QuranWirdProgress? progress;
  final VoidCallback onOpenReader;
  final VoidCallback onMarkCompleted;
  final VoidCallback onDelete;
  final bool large;

  const _ActiveWirdCard({
    required this.wird,
    required this.progress,
    required this.onOpenReader,
    required this.onMarkCompleted,
    required this.onDelete,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fromSuraName = QuranWirdStorage.getSuraName(wird.fromSuraIndex);
    final toSuraName = QuranWirdStorage.getSuraName(wird.toSuraIndex);

    final fromAyah = (wird.fromAyahIndex + 1).toString().toArabicNumbers;
    final toAyah = (wird.toAyahIndex + 1).toString().toArabicNumbers;

    final fromPage = wird.fromPageNumber.toString().toArabicNumbers;
    final toPage = wird.toPageNumber.toString().toArabicNumbers;

    final dayNumber = wird.dayNumber.toString().toArabicNumbers;

    final currentGlobalAyahIndex = progress == null
        ? wird.fromGlobalAyahIndex
        : QuranReaderHelpers.getGlobalAyahIndex(
            suraIndex: progress!.suraIndex,
            ayahIndex: progress!.ayahIndex,
          ).clamp(wird.fromGlobalAyahIndex, wird.toGlobalAyahIndex).toInt();

    final totalAyahs = (wird.toGlobalAyahIndex - wird.fromGlobalAyahIndex + 1)
        .clamp(1, QuranReaderHelpers.totalAyahs)
        .toInt();

    final completedAyahs = progress == null
        ? 0
        : (currentGlobalAyahIndex - wird.fromGlobalAyahIndex)
              .clamp(0, totalAyahs)
              .toInt();

    final remainingAyahs = (totalAyahs - completedAyahs)
        .clamp(0, totalAyahs)
        .toInt();

    final progressValue = totalAyahs == 0 ? 0.0 : completedAyahs / totalAyahs;

    final progressPercent = (progressValue * 100).round().clamp(0, 100);

    final currentPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      currentGlobalAyahIndex,
    );

    final currentSuraName = QuranWirdStorage.getSuraName(
      currentPosition.suraIndex,
    );

    final currentAyah = (currentPosition.ayahIndex + 1)
        .toString()
        .toArabicNumbers;
    final completedAyahsText = completedAyahs.toString().toArabicNumbers;
    final remainingAyahsText = remainingAyahs.toString().toArabicNumbers;
    final progressPercentText = progressPercent.toString().toArabicNumbers;

    final buttonTitle = progress == null ? 'ابدأ القراءة' : 'أكمل القراءة';

    if (large) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          Icons.auto_graph_rounded,
                          size: 17,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تقدّم الورد: $progressPercentText٪',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '$completedAyahsText / ${totalAyahs.toString().toArabicNumbers} آية',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progressValue.clamp(0.0, 1.0),
                        backgroundColor: Colors.black.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      progress == null
                          ? 'ابدأ من أول الورد وسيتم حفظ موضعك تلقائيًا.'
                          : 'وقفت عند سورة $currentSuraName آية $currentAyah، والمتبقي $remainingAyahsText آية.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 9.5,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onMarkCompleted,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'إنهاء يدوي',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onOpenReader,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              buttonTitle,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: theme.colorScheme.primary.withOpacity(0.22),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                wird.planName,
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'اليوم $dayNumber',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _InfoLine(
                      icon: Icons.place_outlined,
                      text:
                          'من سورة $fromSuraName آية $fromAyah - صفحة $fromPage',
                      large: true,
                    ),
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: Icons.flag_outlined,
                      text: 'إلى سورة $toSuraName آية $toAyah - صفحة $toPage',
                      large: true,
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(large ? 12 : 14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: large ? 34 : 34.w,
                height: large ? 34 : 34.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: large ? 17 : 17.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wird.planName,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: _MainPageTypographySizes.actionLabel(
                          context,
                        )?.fontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: large ? 2 : 3.h),
                    Text(
                      'اليوم $dayNumber',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: _MainPageTypographySizes.cardSubtitle(
                          context,
                        ),
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19.sp,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(height: large ? 6 : 12.h),
          _InfoLine(
            icon: Icons.place_outlined,
            text: 'من سورة $fromSuraName آية $fromAyah - صفحة $fromPage',
          ),
          SizedBox(height: large ? 5 : 7.h),
          _InfoLine(
            icon: Icons.flag_outlined,
            text: 'إلى سورة $toSuraName آية $toAyah - صفحة $toPage',
          ),
          SizedBox(height: large ? 6 : 12.h),
          Container(
            padding: EdgeInsets.all(large ? 9 : 11.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      size: 15.sp,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        'تقدّم الورد: $progressPercentText٪',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: _MainPageTypographySizes.cardSubtitle(
                            context,
                          ),
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '$completedAyahsText / ${totalAyahs.toString().toArabicNumbers} آية',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: large ? 6 : 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.r),
                  child: LinearProgressIndicator(
                    minHeight: large ? 5 : 7.h,
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: Colors.black.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: large ? 6 : 8.h),
                Text(
                  progress == null
                      ? 'ابدأ من أول الورد وسيتم حفظ موضعك تلقائيًا.'
                      : 'وقفت عند سورة $currentSuraName آية $currentAyah، والمتبقي $remainingAyahsText آية.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 9.5.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: large ? 10 : 12.h),
          SizedBox(
            height: large ? 36 : null,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMarkCompleted,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'إنهاء يدوي',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: _MainPageTypographySizes.cardSubtitle(
                          context,
                        ),
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOpenReader,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      buttonTitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: _MainPageTypographySizes.cardSubtitle(
                          context,
                        ),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool large;

  const _InfoLine({required this.icon, required this.text, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: large ? 15 : 15.sp, color: Colors.black45),
        SizedBox(width: large ? 7 : 7.w),
        Expanded(
          child: Text(
            text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: large ? 9.5 : 9.8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedPlanCard extends StatelessWidget {
  final QuranKhatmaPlan plan;
  final VoidCallback onDelete;
  final bool large;

  const _CompletedPlanCard({
    required this.plan,
    required this.onDelete,
    this.large = false,
  });

  String get completedDateText {
    final date = plan.completedAt;

    if (date == null) {
      return 'اكتملت الختمة';
    }

    final day = date.day.toString().toArabicNumbers;
    final month = date.month.toString().toArabicNumbers;
    final year = date.year.toString().toArabicNumbers;

    return 'اكتملت بتاريخ $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(large ? 12 : 13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.72),
        borderRadius: BorderRadius.circular(large ? 18 : 18.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.verified_rounded,
            color: theme.colorScheme.primary,
            size: large ? 22 : 24.sp,
          ),
          SizedBox(width: large ? 10 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.name,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: large ? 11.5 : 11.5.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: large ? 3 : 4.h),
                Text(
                  completedDateText,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: large ? 9 : 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: large ? 18 : 18.sp,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCompletedPlansCard extends StatelessWidget {
  const _NoCompletedPlansCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Text(
        'لم تكتمل أي ختمة بعد',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: _MainPageTypographySizes.cardSubtitle(context),
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;

  const _DeleteConfirmDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'cairo'),
      ),
      actionsAlignment: MainAxisAlignment.start,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'cairo')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'حذف',
            style: TextStyle(
              fontFamily: 'cairo',
              color: Colors.red,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
