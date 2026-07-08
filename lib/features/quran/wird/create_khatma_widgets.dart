part of 'create_khatma_page.dart';

class _LargeCreateKhatmaTitle extends StatelessWidget {
  const _LargeCreateKhatmaTitle({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'إنشاء ختمة',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: _LargeCreateKhatmaSizes.cardTitle(context),
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onBackground,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xff222837)
                    : theme.colorScheme.secondary.withOpacity(0.96),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeHeaderCard extends StatelessWidget {
  const _LargeHeaderCard({
    required this.selectedDays,
    required this.pagesPerDay,
    required this.imageAsset,
  });

  final int selectedDays;
  final int pagesPerDay;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isFoldLandscape = _LargeCreateKhatmaSizes.isFoldLandscape(
      context,
    );
    final double imageSize = isFoldLandscape ? 112 : 140;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isFoldLandscape ? 16 : 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'خطة ختمة جديدة',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.display(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'اكتب اسم الورد، واختر عدد الأيام، وسنقسم المصحف إلى ورد يومي بالصفحات.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        height: 1.35,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _LargeMiniInfoBox(
                          title: 'المدة',
                          value:
                              '${selectedDays.toString().toArabicNumbers} يوم',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LargeMiniInfoBox(
                          title: 'ورد يومي',
                          value:
                              '${pagesPerDay.toString().toArabicNumbers} صفحة',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: imageSize,
              height: imageSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  imageAsset,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: isFoldLandscape ? 28 : 34,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'أضف الصورة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: isFoldLandscape ? 8 : 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.78),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeMiniInfoBox extends StatelessWidget {
  const _LargeMiniInfoBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isFoldLandscape = _LargeCreateKhatmaSizes.isFoldLandscape(
      context,
    );
    final double height = isFoldLandscape ? 48 : 52;

    return SizedBox(
      height: height,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: _LargeCreateKhatmaSizes.miniBoxTitle(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.72),
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: _LargeCreateKhatmaSizes.miniBoxValue(context),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeDurationOptionsRow extends StatelessWidget {
  const _LargeDurationOptionsRow({
    required this.quickOptions,
    required this.selectedDays,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onSelectDays,
  });

  final List<int> quickOptions;
  final int selectedDays;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final ValueChanged<int> onSelectDays;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isFold = _LargeCreateKhatmaSizes.isFoldLandscape(context);
        final double gap = isFold ? 7 : 10;
        final double itemWidth =
            (constraints.maxWidth - (gap * (quickOptions.length - 1))) /
            quickOptions.length;

        return Row(
          textDirection: TextDirection.rtl,
          children: [
            for (int index = 0; index < quickOptions.length; index++) ...[
              SizedBox(
                width: itemWidth,
                child: _LargeDayChoiceChip(
                  days: quickOptions[index],
                  isSelected: selectedDays == quickOptions[index],
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  selectedTextColor: selectedTextColor,
                  unselectedTextColor: unselectedTextColor,
                  onTap: () => onSelectDays(quickOptions[index]),
                ),
              ),
              if (index != quickOptions.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _LargeDayChoiceChip extends StatelessWidget {
  const _LargeDayChoiceChip({
    required this.days,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  final int days;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(13),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${days.toString().toArabicNumbers} يوم',
            maxLines: 1,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: _LargeCreateKhatmaSizes.durationChip(context),
              fontWeight: FontWeight.w800,
              color: isSelected ? selectedTextColor : unselectedTextColor,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeCreateKhatmaSizes {
  const _LargeCreateKhatmaSizes._();

  static bool isFoldLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 600 && size.shortestSide < 600;
  }

  static double cardTitle(BuildContext context) {
    return isFoldLandscape(context) ? 18 : 23;
  }

  static double cardSubtitle(BuildContext context) {
    return isFoldLandscape(context) ? 12 : 15;
  }

  static double headerTitle(BuildContext context) {
    return isFoldLandscape(context) ? 16 : 18;
  }

  static double headerSubtitle(BuildContext context) {
    return isFoldLandscape(context) ? 10 : 11.5;
  }

  static double miniBoxTitle(BuildContext context) {
    return isFoldLandscape(context) ? 7.5 : 8.5;
  }

  static double miniBoxValue(BuildContext context) {
    return isFoldLandscape(context) ? 9.5 : 10.5;
  }

  static double durationChip(BuildContext context) {
    return isFoldLandscape(context) ? 8.5 : 10;
  }

  static double actionLabel(BuildContext context) {
    return isFoldLandscape(context) ? 10.5 : 12;
  }
}

class _HeaderCard extends StatelessWidget {
  final int selectedDays;
  final int pagesPerDay;

  const _HeaderCard({required this.selectedDays, required this.pagesPerDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'خطة ختمة جديدة',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اكتب اسم الورد، واختر عدد الأيام، وسنقسم المصحف إلى ورد يومي بالصفحات.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 11.sp,
              height: 1.6,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _MiniInfoBox(
                  title: 'المدة',
                  value: '${selectedDays.toString().toArabicNumbers} يوم',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MiniInfoBox(
                  title: 'ورد يومي',
                  value: '${pagesPerDay.toString().toArabicNumbers} صفحة',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _MiniInfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChoiceChip extends StatelessWidget {
  final int days;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  const _DayChoiceChip({
    required this.days,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          '${days.toString().toArabicNumbers} يوم',
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: isSelected ? selectedTextColor : unselectedTextColor,
          ),
        ),
      ),
    );
  }
}
