import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranPngMushafView extends StatelessWidget {
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onJumpToPage;
  final int selectedPageNumber;
  final bool isDark;

  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final Widget topBar;
  final String currentSuraName;
  final int currentJuzNumber;

  const QuranPngMushafView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.onJumpToPage,
    required this.selectedPageNumber,
    required this.isDark,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.topBar,
    required this.currentSuraName,
    required this.currentJuzNumber,
  });

  static const int firstPageNumber = 1;
  static const int totalPages = 604;
  static const String pagesPath = 'assets/quraan';

  String getPageAssetPath(int pageNumber) {
    return '$pagesPath/$pageNumber.png';
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xffFFFDF6);

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          // صورة المصحف تبدأ بعد شريط اسم السورة والجزء مباشرة.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: 22.h,
                bottom: 24.h,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleControls,
                child: PageView.builder(
                  reverse: true,
                  controller: pageController,
                  itemCount: totalPages,
                  onPageChanged: (pageIndex) {
                    onPageChanged(pageIndex + firstPageNumber);
                  },
                  itemBuilder: (context, pageIndex) {
                    final pageNumber = pageIndex + firstPageNumber;

                    return _MushafImagePage(
                      imagePath: getPageAssetPath(pageNumber),
                      pageNumber: pageNumber,
                      backgroundColor: backgroundColor,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
          ),

          // اسم السورة + الجزء ثابتين فوق صورة المصحف مباشرة.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StaticMushafHeader(
              suraName: currentSuraName,
              juzNumber: currentJuzNumber,
              isDark: isDark,
            ),
          ),

          // رقم الصفحة ثابت: الفردي يمين، الزوجي شمال.
          Positioned(
            left: selectedPageNumber.isEven ? 14.w : null,
            right: selectedPageNumber.isOdd ? 14.w : null,
            bottom: 3.h,
            child: _IslamicPageNumberBadge(
              pageNumber: selectedPageNumber,
              isDark: isDark,
            ),
          ),

          // الشريط السفلي فقط هو اللي يختفي ويظهر.
          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: 28.h,
            child: IgnorePointer(
              ignoring: !controlsVisible,
              child: AnimatedOpacity(
                opacity: controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: _MushafPageControls(
                  selectedPageNumber: selectedPageNumber,
                  currentSuraName: currentSuraName,
                  currentJuzNumber: currentJuzNumber,
                  isDark: isDark,
                  onJumpToPage: onJumpToPage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafImagePage extends StatelessWidget {
  final String imagePath;
  final int pageNumber;
  final Color backgroundColor;
  final bool isDark;

  const _MushafImagePage({
    required this.imagePath,
    required this.pageNumber,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  imagePath,
                  width: constraints.maxWidth,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      height: constraints.maxHeight,
                      child: _MissingMushafPage(
                        pageNumber: pageNumber,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaticMushafHeader extends StatelessWidget {
  final String suraName;
  final int juzNumber;
  final bool isDark;

  const _StaticMushafHeader({
    required this.suraName,
    required this.juzNumber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black87;
    final subTextColor = Colors.black54;

    return Container(
      height: 22.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      color: const Color(0xffFFFDF6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              suraName,
              textAlign: TextAlign.left,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.2.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'الجزء $juzNumber',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 7.8.sp,
                fontWeight: FontWeight.w500,
                color: subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IslamicPageNumberBadge extends StatelessWidget {
  final int pageNumber;
  final bool isDark;

  const _IslamicPageNumberBadge({
    required this.pageNumber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xff224368);
    final backgroundColor = const Color(0xffFFFDF6);
    final textColor = const Color(0xff224368);
    return Container(
      width: 48.w,
      height: 19.h,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.88),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: borderColor.withOpacity(0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.07),
            blurRadius: 6,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4.w,
            child: _SmallDecorationDot(color: borderColor),
          ),
          Positioned(
            right: 4.w,
            child: _SmallDecorationDot(color: borderColor),
          ),
          Text(
            '$pageNumber',
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallDecorationDot extends StatelessWidget {
  final Color color;

  const _SmallDecorationDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.w,
      height: 4.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.65),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MushafPageControls extends StatelessWidget {
  final int selectedPageNumber;
  final String currentSuraName;
  final int currentJuzNumber;
  final bool isDark;
  final ValueChanged<int> onJumpToPage;

  const _MushafPageControls({
    required this.selectedPageNumber,
    required this.currentSuraName,
    required this.currentJuzNumber,
    required this.isDark,
    required this.onJumpToPage,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
    isDark ? const Color(0xff005349) : const Color(0xff224368);

    final safePageNumber = selectedPageNumber.clamp(1, 604);

    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.82),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _PageControlIcon(
            icon: Icons.keyboard_double_arrow_right_rounded,
            onTap: () {
              onJumpToPage((safePageNumber + 10).clamp(1, 604));
            },
          ),
          _PageControlIcon(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              onJumpToPage((safePageNumber + 1).clamp(1, 604));
            },
          ),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.h,
                  showValueIndicator: ShowValueIndicator.onlyForDiscrete,
                  valueIndicatorTextStyle: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 5.5.r,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  min: 1,
                  max: 604,
                  divisions: 603,
                  value: safePageNumber.toDouble(),
                  label:
                  'سورة $currentSuraName | ص $safePageNumber | جزء $currentJuzNumber',
                  onChanged: (value) {
                    onJumpToPage(value.round());
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            '$safePageNumber',
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 5.w),
          _PageControlIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              onJumpToPage((safePageNumber - 1).clamp(1, 604));
            },
          ),
          _PageControlIcon(
            icon: Icons.keyboard_double_arrow_left_rounded,
            onTap: () {
              onJumpToPage((safePageNumber - 10).clamp(1, 604));
            },
          ),
        ],
      ),
    );
  }
}

class _PageControlIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PageControlIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: SizedBox(
        width: 24.w,
        height: 28.h,
        child: Icon(
          icon,
          size: 17.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MissingMushafPage extends StatelessWidget {
  final int pageNumber;
  final bool isDark;

  const _MissingMushafPage({
    required this.pageNumber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: Text(
        'صفحة $pageNumber غير موجودة',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 12.sp,
          color: textColor,
        ),
      ),
    );
  }
}