import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';
import 'prayer_time_highlight_helper.dart';

class PrayTable extends StatefulWidget {
  const PrayTable({
    super.key,
    required this.prayerWeek,
    this.large = false,
  });

  final List<Map<String, String>> prayerWeek;
  final bool large;

  @override
  State<PrayTable> createState() => _PrayTableState();
}

class _PrayTableState extends State<PrayTable> {
  bool _showToday = true;

  bool get _large => widget.large;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? colors.secondary : Colors.white;
    final Color textColor = colors.surface;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: _large ? double.infinity : AppLayoutConstants.mainCardWidth,
        padding: EdgeInsets.symmetric(
          horizontal: _large ? 16 : 12.w,
          vertical: _large ? 16 : 12.h,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(_large ? 24 : 22.r),
          border: Border.all(
            color: textColor.withOpacity(isDark ? 0.08 : 0.055),
            width: _large ? 1 : 0.8.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.14 : 0.045),
              blurRadius: _large ? 18 : 16.r,
              offset: Offset(0, _large ? 8 : 7.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrayerTableHeader(
              showToday: _showToday,
              onTodayTap: () => _setTab(true),
              onWeekTap: () => _setTab(false),
              textColor: textColor,
              primaryColor: colors.primary,
              large: _large,
            ),
            SizedBox(height: _large ? 16 : 12.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: _showToday
                  ? _TodayPrayerSlider(
                key: const ValueKey<String>('today-prayer-slider'),
                prayerWeek: widget.prayerWeek,
                textColor: textColor,
                primaryColor: colors.primary,
                surfaceColor: colors.surface,
                large: _large,
              )
                  : _WeekPrayerGrid(
                key: const ValueKey<String>('week-prayer-grid'),
                prayerWeek: widget.prayerWeek,
                textColor: textColor,
                primaryColor: colors.primary,
                large: _large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setTab(bool showToday) {
    if (_showToday == showToday) return;

    setState(() {
      _showToday = showToday;
    });
  }
}

class _PrayerTableHeader extends StatelessWidget {
  const _PrayerTableHeader({
    required this.showToday,
    required this.onTodayTap,
    required this.onWeekTap,
    required this.textColor,
    required this.primaryColor,
    required this.large,
  });

  final bool showToday;
  final VoidCallback onTodayTap;
  final VoidCallback onWeekTap;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: large ? 42 : 28.w,
          height: large ? 42 : 28.w,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: primaryColor,
            size: large ? 21 : 14.sp,
          ),
        ),
        SizedBox(width: large ? 10 : 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مواقيت الصلاة',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: textColor,
                  fontSize: large ? 18 : 10.5.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              SizedBox(height: large ? 4 : 3.h),
              Text(
                'تابع مواقيت الصلاة',
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withOpacity(0.52),
                  fontSize: large ? 11 : 7.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: large ? 12 : 8.w),
        _PrayerTableTabSwitch(
          showToday: showToday,
          onTodayTap: onTodayTap,
          onWeekTap: onWeekTap,
          textColor: textColor,
          primaryColor: primaryColor,
          large: large,
        ),
      ],
    );
  }
}

class _PrayerTableTabSwitch extends StatelessWidget {
  const _PrayerTableTabSwitch({
    required this.showToday,
    required this.onTodayTap,
    required this.onWeekTap,
    required this.textColor,
    required this.primaryColor,
    required this.large,
  });

  final bool showToday;
  final VoidCallback onTodayTap;
  final VoidCallback onWeekTap;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: large ? 40 : 32.h,
      padding: EdgeInsets.all(large ? 4 : 3.w),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.055),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrayerTableTabButton(
            title: 'اليوم',
            selected: showToday,
            onTap: onTodayTap,
            textColor: textColor,
            primaryColor: primaryColor,
            large: large,
          ),
          _PrayerTableTabButton(
            title: 'الأسبوع',
            selected: !showToday,
            onTap: onWeekTap,
            textColor: textColor,
            primaryColor: primaryColor,
            large: large,
          ),
        ],
      ),
    );
  }
}

class _PrayerTableTabButton extends StatelessWidget {
  const _PrayerTableTabButton({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.textColor,
    required this.primaryColor,
    required this.large,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          height: large ? 32 : 26.h,
          padding: EdgeInsets.symmetric(horizontal: large ? 18 : 12.w),
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.22),
                blurRadius: large ? 12 : 10.r,
                offset: Offset(0, large ? 4 : 3.h),
              ),
            ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              color: selected ? Colors.white : textColor.withOpacity(0.58),
              fontSize: large ? 12 : 8.8.sp,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayPrayerSlider extends StatelessWidget {
  const _TodayPrayerSlider({
    super.key,
    required this.prayerWeek,
    required this.textColor,
    required this.primaryColor,
    required this.surfaceColor,
    required this.large,
  });

  final List<Map<String, String>> prayerWeek;
  final Color textColor;
  final Color primaryColor;
  final Color surfaceColor;
  final bool large;

  static const List<_PrayerTimeMeta> _todayItems = [
    _PrayerTimeMeta(
      key: 'fajr',
      title: 'الفجر',
      icon: Icons.wb_twilight_rounded,
    ),
    _PrayerTimeMeta(
      key: 'sunrise',
      title: 'الشروق',
      icon: Icons.wb_sunny_outlined,
    ),
    _PrayerTimeMeta(
      key: 'dhuhr',
      title: 'الظهر',
      icon: Icons.wb_sunny_rounded,
    ),
    _PrayerTimeMeta(
      key: 'asr',
      title: 'العصر',
      icon: Icons.wb_sunny_outlined,
    ),
    _PrayerTimeMeta(
      key: 'maghrib',
      title: 'المغرب',
      icon: Icons.nights_stay_rounded,
    ),
    _PrayerTimeMeta(
      key: 'isha',
      title: 'العشاء',
      icon: Icons.dark_mode_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, String>? today =
    PrayerTimeHighlightHelper.getTodayPrayerTimes(prayerWeek);
    final String? highlightedKey = today == null
        ? null
        : PrayerTimeHighlightHelper.getNextPrayerKey(today);

    return SizedBox(
      height: large ? 92 : 78.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: false,
        physics: const BouncingScrollPhysics(),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            for (int index = 0; index < _todayItems.length; index++) ...[
              _TodayPrayerTile(
                item: _todayItems[index],
                time: today == null ? '--:--' : _timeFor(today, _todayItems[index].key),
                highlighted: highlightedKey == _todayItems[index].key,
                textColor: textColor,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                large: large,
              ),
              if (index != _todayItems.length - 1)
                SizedBox(width: large ? 10 : 8.w),
            ],
          ],
        ),
      ),
    );
  }

  String _timeFor(Map<String, String> day, String key) {
    final String? value = day[key];
    return value == null || value.trim().isEmpty ? '--:--' : value.trim();
  }
}

class _TodayPrayerTile extends StatelessWidget {
  const _TodayPrayerTile({
    required this.item,
    required this.time,
    required this.highlighted,
    required this.textColor,
    required this.primaryColor,
    required this.surfaceColor,
    required this.large,
  });

  final _PrayerTimeMeta item;
  final String time;
  final bool highlighted;
  final Color textColor;
  final Color primaryColor;
  final Color surfaceColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final Color foreground = highlighted ? Colors.white : textColor;
    final Color iconColor = highlighted ? Colors.white : primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: large ? 74 : 58.w,
      height: large ? 92 : 78.h,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 8 : 7.w,
        vertical: large ? 10 : 8.h,
      ),
      decoration: BoxDecoration(
        color: highlighted ? primaryColor : surfaceColor.withOpacity(0.035),
        borderRadius: BorderRadius.circular(large ? 18 : 16.r),
        border: Border.all(
          color: highlighted
              ? primaryColor.withOpacity(0.22)
              : textColor.withOpacity(0.075),
          width: large ? 1 : 0.8.w,
        ),
        boxShadow: highlighted
            ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.24),
            blurRadius: large ? 14 : 12.r,
            offset: Offset(0, large ? 5 : 4.h),
          ),
        ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: large ? 18 : 14.sp,
            color: iconColor,
          ),
          SizedBox(height: large ? 8 : 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              style: AppTextStyles.caption(context).copyWith(
                color: foreground,
                fontSize: large ? 12 : 8.4.sp,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: large ? 7 : 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              style: AppTextStyles.caption(context).copyWith(
                color: foreground.withOpacity(highlighted ? 0.92 : 0.72),
                fontSize: large ? 11 : 8.sp,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPrayerGrid extends StatelessWidget {
  const _WeekPrayerGrid({
    super.key,
    required this.prayerWeek,
    required this.textColor,
    required this.primaryColor,
    required this.large,
  });

  final List<Map<String, String>> prayerWeek;
  final Color textColor;
  final Color primaryColor;
  final bool large;

  static const List<_PrayerTimeMeta> _columns = [
    _PrayerTimeMeta(key: 'day', title: 'الصلاة', icon: Icons.calendar_today),
    _PrayerTimeMeta(key: 'fajr', title: 'الفجر', icon: Icons.wb_twilight_rounded,),
    _PrayerTimeMeta(key: 'sunrise', title: 'الشروق', icon: Icons.wb_sunny_outlined),
    _PrayerTimeMeta(key: 'dhuhr', title: 'الظهر', icon: Icons.wb_sunny_rounded),
    _PrayerTimeMeta(key: 'asr', title: 'العصر', icon: Icons.wb_sunny_outlined),
    _PrayerTimeMeta(key: 'maghrib', title: 'المغرب', icon: Icons.nights_stay_rounded),
    _PrayerTimeMeta(key: 'isha', title: 'العشاء', icon: Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    if (prayerWeek.isEmpty) {
      return SizedBox(
        height: large ? 170 : 150.h,
        child: Center(
          child: Text(
            'لا توجد مواقيت متاحة الآن',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.caption(context).copyWith(
              color: textColor.withOpacity(0.64),
              fontSize: large ? 12 : 9.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final Map<String, String>? today =
    PrayerTimeHighlightHelper.getTodayPrayerTimes(prayerWeek);
    final String? highlightedPrayerKey = today == null
        ? null
        : PrayerTimeHighlightHelper.getNextPrayerKey(today);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.035),
        borderRadius: BorderRadius.circular(large ? 18 : 16.r),
        border: Border.all(
          color: textColor.withOpacity(0.06),
          width: large ? 1 : 0.8.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WeekHeaderRow(
            columns: _columns,
            textColor: textColor,
            large: large,
          ),
          for (int index = 0; index < prayerWeek.length; index++)
            _WeekDataRow(
              day: prayerWeek[index],
              columns: _columns,
              highlightedPrayerKey: highlightedPrayerKey,
              textColor: textColor,
              primaryColor: primaryColor,
              large: large,
              showDivider: index != prayerWeek.length - 1,
            ),
        ],
      ),
    );
  }
}

class _WeekHeaderRow extends StatelessWidget {
  const _WeekHeaderRow({
    required this.columns,
    required this.textColor,
    required this.large,
  });

  final List<_PrayerTimeMeta> columns;
  final Color textColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: large ? 34 : 28.h,
      color: textColor.withOpacity(0.035),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (int index = 0; index < columns.length; index++)
            Expanded(
              flex: columns[index].key == 'day' ? 13 : 11,
              child: _WeekCellFrame(
                showLeftBorder: index != columns.length - 1,
                borderColor: textColor.withOpacity(0.055),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    columns[index].title,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    style: AppTextStyles.caption(context).copyWith(
                      color: textColor.withOpacity(0.62),
                      fontSize: large ? 11 : 8.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekDataRow extends StatelessWidget {
  const _WeekDataRow({
    required this.day,
    required this.columns,
    required this.highlightedPrayerKey,
    required this.textColor,
    required this.primaryColor,
    required this.large,
    required this.showDivider,
  });

  final Map<String, String> day;
  final List<_PrayerTimeMeta> columns;
  final String? highlightedPrayerKey;
  final Color textColor;
  final Color primaryColor;
  final bool large;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final bool isToday = PrayerTimeHighlightHelper.isTodayRow(day);

    return Container(
      height: large ? 36 : 30.h,
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
          bottom: BorderSide(
            color: textColor.withOpacity(0.055),
            width: large ? 1 : 0.6.w,
          ),
        )
            : null,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (int index = 0; index < columns.length; index++)
            Expanded(
              flex: columns[index].key == 'day' ? 13 : 11,
              child: _WeekCellFrame(
                showLeftBorder: index != columns.length - 1,
                borderColor: textColor.withOpacity(0.045),
                child: _WeekTextPill(
                  text: _valueFor(columns[index].key),
                  highlighted: isToday &&
                      (columns[index].key == 'day' ||
                          columns[index].key == highlightedPrayerKey),
                  textColor: textColor,
                  primaryColor: primaryColor,
                  large: large,
                  isDay: columns[index].key == 'day',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _valueFor(String key) {
    final String? value = day[key];
    return value == null || value.trim().isEmpty ? '--:--' : value.trim();
  }
}

class _WeekCellFrame extends StatelessWidget {
  const _WeekCellFrame({
    required this.child,
    required this.showLeftBorder,
    required this.borderColor,
  });

  final Widget child;
  final bool showLeftBorder;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: showLeftBorder
            ? Border(
          left: BorderSide(color: borderColor),
        )
            : null,
      ),
      child: child,
    );
  }
}

class _WeekTextPill extends StatelessWidget {
  const _WeekTextPill({
    required this.text,
    required this.highlighted,
    required this.textColor,
    required this.primaryColor,
    required this.large,
    required this.isDay,
  });

  final String text;
  final bool highlighted;
  final Color textColor;
  final Color primaryColor;
  final bool large;
  final bool isDay;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.center,
      constraints: BoxConstraints(
        minWidth: highlighted ? (large ? 52 : 42.w) : 0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 7 : 5.w,
        vertical: large ? 5 : 4.h,
      ),
      decoration: BoxDecoration(
        color: highlighted ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textAlign: TextAlign.center,
          textDirection: isDay ? TextDirection.rtl : TextDirection.ltr,
          maxLines: 1,
          style: AppTextStyles.caption(context).copyWith(
            color: highlighted ? Colors.white : textColor.withOpacity(0.70),
            fontSize: large ? 11 : (isDay ? 7.7.sp : 7.9.sp),
            fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PrayerTimeMeta {
  const _PrayerTimeMeta({
    required this.key,
    required this.title,
    required this.icon,
  });

  final String key;
  final String title;
  final IconData icon;
}
