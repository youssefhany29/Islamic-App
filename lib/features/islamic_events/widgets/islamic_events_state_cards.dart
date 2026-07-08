import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
bool _eventsStateLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventsOnlineNoticeCard extends StatelessWidget {
  const IslamicEventsOnlineNoticeCard({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _StatusCard(
      icon: Icons.cloud_done_rounded,
      text: 'تم تحديث المناسبات من الإنترنت للدقة الأعلى.',
      buttonText: 'تحديث',
      color: theme.colorScheme.primary.withOpacity(0.10),
      onTap: onRefresh,
    );
  }
}

class IslamicEventsOfflineNoticeCard extends StatelessWidget {
  const IslamicEventsOfflineNoticeCard({
    super.key,
    required this.message,
    required this.onRefresh,
  });

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _StatusCard(
      icon: Icons.wifi_off_rounded,
      text: message,
      buttonText: 'تحديث',
      color: theme.colorScheme.secondary,
      onTap: onRefresh,
    );
  }
}

class IslamicEventsLoadingCard extends StatelessWidget {
  const IslamicEventsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsStateLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 12.w,
          vertical: large ? 12 : 11.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(large ? 18 : 18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.35),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            SizedBox(
              width: large ? 22 : 20.w,
              height: large ? 22 : 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: large ? 10 : 9.w),
            Expanded(
              child: Text(
                'جاري تحميل المناسبات...',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                  color: theme.colorScheme.surface,
                  height: 1.35
),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IslamicEventsErrorCard extends StatelessWidget {
  const IslamicEventsErrorCard({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsStateLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(large ? 16 : 14.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(large ? 20 : 18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: large ? 24 : 22.sp,
                ),
                SizedBox(width: large ? 9 : 8.w),
                Expanded(
                  child: Text(
                    'تعذر تحميل المناسبات الآن',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface
),
                  ),
                ),
              ],
            ),
            SizedBox(height: large ? 6 : 5.h),
            Text(
              'حاول مرة أخرى أو تأكد من اتصال الإنترنت.',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                color: theme.colorScheme.surface.withOpacity(0.75),
                height: 1.5
),
            ),
            SizedBox(height: large ? 12 : 10.h),
            SizedBox(
              width: double.infinity,
              child: _StatusRefreshButton(
                buttonText: 'إعادة المحاولة',
                onTap: onRefresh,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IslamicEventsEmptyCard extends StatelessWidget {
  const IslamicEventsEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsStateLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(large ? 16 : 14.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(large ? 20 : 18.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.35),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_busy_rounded,
              color: theme.colorScheme.primary,
              size: large ? 24 : 22.sp,
            ),
            SizedBox(width: large ? 9 : 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'لا توجد مناسبات حسب الاختيار الحالي',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                      color: theme.colorScheme.surface
),
                  ),
                  SizedBox(height: large ? 4 : 3.h),
                  Text(
                    'جرّب تغيير الفلتر أو اختيار يوم آخر من التقويم.',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w500,
                      color: theme.colorScheme.surface.withOpacity(0.7),
                      height: 1.45
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

class IslamicEventsSelectedDateCard extends StatelessWidget {
  const IslamicEventsSelectedDateCard({
    super.key,
    required this.selectedDate,
    required this.onClear,
  });

  final DateTime selectedDate;
  final VoidCallback onClear;

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsStateLargeScreen(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 11.w,
          vertical: large ? 10 : 9.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(large ? 16 : 16.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.35),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.event_rounded,
              color: theme.colorScheme.primary,
              size: large ? 18 : 17.sp,
            ),
            SizedBox(width: large ? 8 : 7.w),
            Expanded(
              child: Text(
                'عرض مناسبات ${_weekdayName(selectedDate.weekday)} ${selectedDate.day}/${selectedDate.month}',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w700,
                  color: theme.colorScheme.surface,
                  height: 1.4
),
              ),
            ),
            SizedBox(width: large ? 8 : 7.w),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: EdgeInsets.all(large ? 4 : 4.w),
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.surface.withOpacity(0.75),
                  size: large ? 18 : 17.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.text,
    required this.buttonText,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String buttonText;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsStateLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(large ? 12 : 11.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(large ? 18 : 17.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(isDark ? 0.18 : 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusIconBox(
                  icon: icon,
                  iconBox: large ? 30 : 28.w,
                  iconSize: large ? 16 : 15.sp,
                ),
                SizedBox(width: large ? 8 : 7.w),
                Expanded(
                  child: _StatusText(text: text, large: large),
                ),
              ],
            ),
            SizedBox(height: large ? 9 : 8.h),
            _StatusRefreshButton(
              buttonText: buttonText,
              onTap: onTap,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIconBox extends StatelessWidget {
  const _StatusIconBox({
    required this.icon,
    required this.iconBox,
    required this.iconSize,
  });

  final IconData icon;
  final double iconBox;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: iconBox,
      height: iconBox,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: iconSize,
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({
    required this.text,
    required this.large,
  });

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        softWrap: true,
        style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
          color: theme.colorScheme.surface,
          height: 1.5
),
      ),
    );
  }
}

class _StatusRefreshButton extends StatelessWidget {
  const _StatusRefreshButton({
    required this.buttonText,
    required this.onTap,
    required this.fullWidth,
  });

  final String buttonText;
  final Future<void> Function() onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsStateLargeScreen(context);

    final Widget button = Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(large ? 13 : 13.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(large ? 13 : 13.r),
        child: Container(
          height: large ? 32 : 31.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: large ? 14 : 12.w),
          child: Text(
            buttonText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2
),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
