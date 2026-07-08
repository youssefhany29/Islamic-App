import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/islamic_event_filter.dart';
import 'islamic_events_section_title.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
bool _eventsFiltersLargeScreen(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 700 && size.height >= 500);
}

class IslamicEventsFilterChips extends StatelessWidget {
  const IslamicEventsFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final IslamicEventFilter selectedFilter;
  final ValueChanged<IslamicEventFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final bool large = _eventsFiltersLargeScreen(context);

    final filters = <_FilterChipData>[
      _FilterChipData(
        filter: IslamicEventFilter.all,
        label: 'الكل',
        icon: Icons.grid_view_rounded,
      ),
      _FilterChipData(
        filter: IslamicEventFilter.fasting,
        label: 'الصيام',
        icon: Icons.nightlight_round,
      ),
      _FilterChipData(
        filter: IslamicEventFilter.ramadan,
        label: 'رمضان',
        icon: Icons.mosque_rounded,
      ),
      _FilterChipData(
        filter: IslamicEventFilter.eid,
        label: 'الأعياد',
        icon: Icons.celebration_rounded,
      ),
      _FilterChipData(
        filter: IslamicEventFilter.special,
        label: 'مناسبات',
        icon: Icons.star_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const IslamicEventsSectionTitle(
          title: 'تصفية المناسبات',
          icon: Icons.tune_rounded,
        ),
        SizedBox(height: large ? 10 : 8.h),
        SizedBox(
          height: large ? 42 : 44.h,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filters.length,
              separatorBuilder: (_, __) => SizedBox(width: large ? 8 : 8.w),
              itemBuilder: (context, index) {
                final item = filters[index];

                return _FilterChipItem(
                  label: item.label,
                  icon: item.icon,
                  isSelected: selectedFilter == item.filter,
                  onTap: () {
                    AppHaptics.tap(context);
                    onFilterSelected(item.filter);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipData {
  final IslamicEventFilter filter;
  final String label;
  final IconData icon;

  const _FilterChipData({
    required this.filter,
    required this.label,
    required this.icon,
  });
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventsFiltersLargeScreen(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(large ? 18 : 18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(large ? 18 : 18.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: large ? 12 : 12.w,
            vertical: large ? 8 : 8.h,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(large ? 18 : 18.r),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(isDark ? 0.16 : 0.35),
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: large ? 25 : 25.w,
                height: large ? 25 : 25.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.16)
                      : theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.08),
                  borderRadius: BorderRadius.circular(large ? 10 : 10.r),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  size: large ? 15 : 15.sp,
                ),
              ),
              SizedBox(width: large ? 6 : 6.w),
              Text(
                label,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : theme.colorScheme.surface,
                  height: 1.2
),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
