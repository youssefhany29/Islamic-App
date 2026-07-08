part of 'islamic_event_details_page.dart';

class _DetailsMasonry extends StatelessWidget {
  const _DetailsMasonry({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length <= 1) {
      return Column(children: children);
    }

    final List<Widget> right = <Widget>[];
    final List<Widget> left = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      if (i.isEven) {
        right.add(children[i]);
      } else {
        left.add(children[i]);
      }
    }

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < right.length; i++) ...[
                right[i],
                if (i != right.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < left.length; i++) ...[
                left[i],
                if (i != left.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroDetailsCard extends StatelessWidget {
  const _HeroDetailsCard({
    required this.event,
    required this.daysText,
    required this.gregorianDateText,
    required this.typeText,
    required this.typeIcon,
  });

  final IslamicEventModel event;
  final String daysText;
  final String gregorianDateText;
  final String typeText;
  final IconData typeIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    final double padding = large ? 18 : 18.w;
    final double radius = large ? 24 : 24.r;
    final double iconBox = large ? 48 : 48.w;
    final double iconSize = large ? 24 : 25.sp;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(large ? 17 : 17.r),
                  ),
                  child: Icon(event.icon, color: Colors.white, size: iconSize),
                ),
                SizedBox(width: large ? 10 : 10.w),
                Expanded(
                  child: Text(
                    event.title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    locale: const Locale('ar'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: large ? 16 : 16.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool twoRows = !large || constraints.maxWidth < 720;

                final items = [
                  _HeroMiniInfo(
                    icon: Icons.access_time_rounded,
                    title: 'الموعد',
                    value: daysText,
                  ),
                  _HeroMiniInfo(
                    icon: Icons.calendar_month_rounded,
                    title: 'ميلادي',
                    value: gregorianDateText,
                  ),
                  _HeroMiniInfo(
                    icon: Icons.nightlight_round,
                    title: 'هجري',
                    value: event.hijriDateText,
                    valueFontSize: large ? 9 : 8.sp,
                    valueFontWeight: FontWeight.w500,
                    valueMaxLines: 2,
                  ),
                  _HeroMiniInfo(
                    icon: typeIcon,
                    title: 'النوع',
                    value: typeText,
                  ),
                ];

                if (twoRows) {
                  return Column(
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(child: items[0]),
                          SizedBox(width: large ? 8 : 8.w),
                          Expanded(child: items[1]),
                        ],
                      ),
                      SizedBox(height: large ? 8 : 8.h),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(child: items[2]),
                          SizedBox(width: large ? 8 : 8.w),
                          Expanded(child: items[3]),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      Expanded(child: items[i]),
                      if (i != items.length - 1) const SizedBox(width: 8),
                    ],
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

class _HeroMiniInfo extends StatelessWidget {
  const _HeroMiniInfo({
    required this.icon,
    required this.title,
    required this.value,
    this.valueFontSize,
    this.valueFontWeight,
    this.valueMaxLines = 1,
  });

  final IconData icon;
  final String title;
  final String value;
  final double? valueFontSize;
  final FontWeight? valueFontWeight;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final bool large = _eventDetailsLargeScreen(context);

    return Container(
      constraints: BoxConstraints(minHeight: large ? 58 : 58.h),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 9 : 9.w,
        vertical: large ? 8 : 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(large ? 15 : 15.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.white, size: large ? 15 : 15.sp),
          SizedBox(width: large ? 5 : 5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.70),
                    ),
                  ),
                ),
                SizedBox(height: large ? 2 : 2.h),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLines: valueMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: valueFontWeight ?? FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 14 : 14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(large ? 20 : 20.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(isDark ? 0.20 : 0.42),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: large ? 40 : 40.w,
              height: large ? 40 : 40.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(
                  isDark ? 0.24 : 0.10,
                ),
                borderRadius: BorderRadius.circular(large ? 14 : 14.r),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: large ? 19 : 20.sp,
              ),
            ),
            SizedBox(width: large ? 10 : 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                  SizedBox(height: large ? 4 : 4.h),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      body,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.surface.withOpacity(0.70),
                        height: 1.55,
                      ),
                    ),
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

class _FastingIntentionCard extends StatelessWidget {
  const _FastingIntentionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 14 : 14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(large ? 20 : 20.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.nightlight_round,
              color: theme.colorScheme.primary,
              size: large ? 22 : 24.sp,
            ),
            SizedBox(width: large ? 10 : 10.w),
            Expanded(
              child: Text(
                'لا تنس نية الصيام قبل الفجر، وأكثر من الدعاء والذكر والعمل الصالح.',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.surface,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
