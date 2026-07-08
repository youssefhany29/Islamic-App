import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../hiding/quran_hide_mode.dart';
import '../theme/quran_reader_theme.dart';

class QpcReaderOverlayControls extends StatelessWidget {
  const QpcReaderOverlayControls({
    super.key,
    required this.visible,
    required this.selectedPageNumber,
    required this.currentSuraName,
    required this.currentJuzNumber,
    required this.hideMode,
    required this.readerTheme,
    required this.onJumpToPage,
    required this.onToggleHideMode,
    required this.onOpenThemePicker,
    required this.onStopAudio,
    required this.isAudioPlaying,
  });

  final bool visible;
  final int selectedPageNumber;
  final String currentSuraName;
  final int currentJuzNumber;
  final QuranHideMode hideMode;
  final QuranReaderTheme readerTheme;
  final ValueChanged<int> onJumpToPage;
  final VoidCallback onToggleHideMode;
  final VoidCallback onOpenThemePicker;
  final VoidCallback onStopAudio;
  final bool isAudioPlaying;

  @override
  Widget build(BuildContext context) {
    final int safePageNumber = selectedPageNumber.clamp(1, 604);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: 54.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: readerTheme.controlsBackgroundColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: readerTheme.dividerColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    readerTheme.isDarkLike ? 0.35 : 0.14,
                  ),
                  blurRadius: 14,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              children: [
                _ControlIcon(
                  icon: _hideIcon(),
                  tooltip: hideMode.label,
                  color: readerTheme.controlsTextColor,
                  onTap: onToggleHideMode,
                ),
                _ControlIcon(
                  icon: Icons.palette_outlined,
                  tooltip: 'خلفية المصحف',
                  color: readerTheme.controlsTextColor,
                  onTap: onOpenThemePicker,
                ),
                if (isAudioPlaying)
                  _ControlIcon(
                    icon: Icons.stop_rounded,
                    tooltip: 'إيقاف الصوت',
                    color: readerTheme.controlsTextColor,
                    onTap: onStopAudio,
                  ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.h,
                          showValueIndicator:
                          ShowValueIndicator.onlyForDiscrete,
                          valueIndicatorTextStyle: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 9.sp,
                            color: readerTheme.controlsTextColor,
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
                      Text(
                        'ص $safePageNumber  •  جزء $currentJuzNumber',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 8.5.sp,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: readerTheme.controlsTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                _ControlIcon(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'الصفحة التالية',
                  color: readerTheme.controlsTextColor,
                  onTap: () {
                    onJumpToPage((safePageNumber + 1).clamp(1, 604));
                  },
                ),
                _ControlIcon(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'الصفحة السابقة',
                  color: readerTheme.controlsTextColor,
                  onTap: () {
                    onJumpToPage((safePageNumber - 1).clamp(1, 604));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _hideIcon() {
    switch (hideMode) {
      case QuranHideMode.visible:
        return Icons.visibility_outlined;
      case QuranHideMode.partial:
        return Icons.visibility_off_outlined;
      case QuranHideMode.full:
        return Icons.lock_outline_rounded;
    }
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: 34.w,
          height: 42.h,
          child: Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}