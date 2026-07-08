part of '../qpc_connected_mushaf_page.dart';

class _FontScaleSlider extends StatelessWidget {
  const _FontScaleSlider({
    required this.readerTheme,
    required this.value,
    required this.onChanged,
  });

  final QuranReaderTheme readerTheme;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isLargeSheet = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeSheet ? 10 : 12.w,
        vertical: isLargeSheet ? 7 : 10.h,
      ),
      decoration: BoxDecoration(
        color: readerTheme.controlsBackgroundColor.withOpacity(
          readerTheme.isDarkLike ? 0.30 : 0.07,
        ),
        borderRadius: BorderRadius.circular(isLargeSheet ? 13 : 16.r),
        border: Border.all(color: readerTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اسحب لتغيير حجم الخط',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'cairo',
              fontSize: isLargeSheet ? 9.5 : 11.sp,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: readerTheme.textColor,
            ),
          ),
          SizedBox(height: isLargeSheet ? 3 : 6.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: isLargeSheet ? 2 : 3,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: isLargeSheet ? 4 : 5.r,
              ),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(0.92, 1.18).toDouble(),
              min: 0.92,
              max: 1.18,
              divisions: 13,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTitle extends StatelessWidget {
  const _SettingsTitle({required this.title, required this.readerTheme});

  final String title;
  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    final bool isLargeSheet = MediaQuery.sizeOf(context).width >= 600;

    return Text(
      title,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'cairo',
        fontSize: isLargeSheet ? 10 : 12.sp,
        fontWeight: FontWeight.w900,
        color: readerTheme.secondaryTextColor,
        height: 1.15,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.readerTheme,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final QuranReaderTheme readerTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isLargeSheet = MediaQuery.sizeOf(context).width >= 600;

    return InkWell(
      borderRadius: BorderRadius.circular(isLargeSheet ? 13 : 16.r),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: isLargeSheet ? 42 : 54.h),
        padding: EdgeInsets.symmetric(
          horizontal: isLargeSheet ? 10 : 12.w,
          vertical: isLargeSheet ? 7 : 9.h,
        ),
        decoration: BoxDecoration(
          color: readerTheme.controlsBackgroundColor.withOpacity(
            readerTheme.isDarkLike ? 0.30 : 0.07,
          ),
          borderRadius: BorderRadius.circular(isLargeSheet ? 13 : 16.r),
          border: Border.all(color: readerTheme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: readerTheme.selectedWordTextColor,
              size: isLargeSheet ? 18 : 22.sp,
            ),
            SizedBox(width: isLargeSheet ? 8 : 10.w),
            Expanded(
              child: Text(
                subtitle.isEmpty ? title : '$title\n$subtitle',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeSheet
                      ? (subtitle.isEmpty ? 9.8 : 8.8)
                      : (subtitle.isEmpty ? 11.5.sp : 10.5.sp),
                  height: isLargeSheet ? 1.18 : 1.25,
                  fontWeight: FontWeight.w800,
                  color: readerTheme.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
