part of 'memorization_training_session_page.dart';

class _RescueStepsCard extends StatelessWidget {
  const _RescueStepsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final steps = const [
      _RescueStepData(
        title: 'قراءة هادئة',
        subtitle: 'اقرأ المقطع كاملًا ببطء، ولا تستعجل الانتقال للاختبار.',
        icon: Icons.menu_book_rounded,
      ),
      _RescueStepData(
        title: 'تكرار مركز',
        subtitle: 'كرر الموضع الذي كان صعبًا مرتين أو ثلاثًا.',
        icon: Icons.repeat_rounded,
      ),
      _RescueStepData(
        title: 'إخفاء واستدعاء',
        subtitle: 'اخفِ النص وحاول استدعاء الآيات من الذاكرة.',
        icon: Icons.visibility_off_rounded,
      ),
      _RescueStepData(
        title: 'تقييم التحسن',
        subtitle: 'لو اتحسن اختر سهل/جيد، ولو ما زال صعبًا اختر صعب/نسيت.',
        icon: Icons.fact_check_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.075),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.healing_rounded,
                  color: theme.colorScheme.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'لماذا ظهرت جلسة الإنقاذ؟',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'لأن هذا المقطع اتقيّم سابقًا صعبًا أو منسيًا، فبنراجعه بطريقة أخف وأقرب.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.surface.withOpacity(0.60),
                        height: 1.42,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...List.generate(steps.length, (index) {
            final step = steps[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == steps.length - 1 ? 0 : 8.h,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 30.w,
                      height: 30.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Icon(
                        step.icon,
                        color: theme.colorScheme.primary,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            step.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.surface,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            step.subtitle,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.surface.withOpacity(
                                0.56,
                              ),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RescueStepData {
  const _RescueStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.title,
    required this.subtitle,
    required this.task,
    required this.isCompleted,
    required this.isRescueSession,
  });

  final String title;
  final String subtitle;
  final MemorizationTodayTaskModel task;
  final bool isCompleted;
  final bool isRescueSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isRescueSession) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Text(
                'إنقاذ',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
          if (isCompleted) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Text(
                'مكتملة',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.76),
              height: 1.45,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  task.scopeTitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${task.subtitle} • ${task.expectedMinutes} دقيقة تقريبًا',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.72),
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.buttonText,
    required this.onTap,
    this.isLocked = false,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLocked;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDone
              ? theme.colorScheme.primary.withOpacity(0.28)
              : theme.colorScheme.outline.withOpacity(0.14),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.11),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Center(
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      color: theme.colorScheme.primary,
                      size: 22.sp,
                    )
                  : Text(
                      number,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.surface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.surface.withOpacity(0.58),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _SmallActionButton(
                    text: buttonText,
                    isLocked: isLocked,
                    onTap: onTap,
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

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.text,
    required this.onTap,
    this.isLocked = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isLocked
          ? theme.colorScheme.surface.withOpacity(0.08)
          : theme.colorScheme.primary.withOpacity(0.10),
      borderRadius: BorderRadius.circular(30.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(30.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Text(
            text,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: isLocked
                  ? theme.colorScheme.surface.withOpacity(0.45)
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.selectedRating,
    required this.onRatingSelected,
    required this.isLocked,
    required this.isRescueSession,
    required this.isSmartTestSession,
  });

  final String? selectedRating;
  final bool isLocked;
  final bool isRescueSession;
  final bool isSmartTestSession;
  final ValueChanged<String> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    final ratings = const [
      _RatingOption(
        value: 'easy',
        title: 'سهل',
        subtitle: 'حفظته بثبات',
        icon: Icons.sentiment_satisfied_alt_rounded,
      ),
      _RatingOption(
        value: 'good',
        title: 'جيد',
        subtitle: 'أخطاء بسيطة',
        icon: Icons.thumb_up_alt_rounded,
      ),
      _RatingOption(
        value: 'hard',
        title: 'صعب',
        subtitle: 'محتاج مراجعة',
        icon: Icons.warning_amber_rounded,
      ),
      _RatingOption(
        value: 'forgot',
        title: 'نسيت',
        subtitle: 'خطة إنقاذ',
        icon: Icons.refresh_rounded,
      ),
    ];

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isRescueSession
                ? 'قيّم التحسن'
                : isSmartTestSession
                ? 'قيّم الاختبار'
                : 'قيّم حفظك',
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.surface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isLocked
                ? 'تم تسجيل تقييم هذه الجلسة بالفعل.'
                : isRescueSession
                ? 'لو اتحسن اختر سهل أو جيد. لو ما زال صعبًا، سيعود قريبًا للإنقاذ.'
                : isSmartTestSession
                ? 'اختار تقييمك بصدق؛ الاختبار للتثبيت وليس للضغط.'
                : 'التقييم هو اللي هيحدد هل المقطع يرجع قريبًا أم يتباعد.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.surface.withOpacity(0.58),
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ratings.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 1.82,
            ),
            itemBuilder: (context, index) {
              final rating = ratings[index];
              final isSelected = selectedRating == rating.value;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => onRatingSelected(rating.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : theme.colorScheme.background.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.55)
                            : theme.colorScheme.outline.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          rating.icon,
                          color: isLocked
                              ? theme.colorScheme.surface.withOpacity(0.38)
                              : theme.colorScheme.primary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                rating.title,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isLocked
                                      ? theme.colorScheme.surface.withOpacity(
                                          0.50,
                                        )
                                      : theme.colorScheme.surface,
                                  height: 1,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                rating.subtitle,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 7.4.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.surface.withOpacity(
                                    0.55,
                                  ),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RatingOption {
  const _RatingOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}
