import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/quran_reader_theme.dart';

class QpcTopControlsBar extends StatelessWidget {
  const QpcTopControlsBar({
    super.key,
    required this.visible,
    required this.readerTheme,
    required this.connectedMode,
    required this.onBack,
    required this.onSearch,
    required this.onIndex,
    required this.onSettings,
    required this.onSaveSurah,
    required this.onToggleConnectedMode,
  });

  final bool visible;
  final QuranReaderTheme readerTheme;
  final bool connectedMode;

  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onIndex;
  final VoidCallback onSettings;
  final VoidCallback onSaveSurah;
  final VoidCallback onToggleConnectedMode;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              _BackButton(
                readerTheme: readerTheme,
                onTap: onBack,
              ),
              const Spacer(),
              _ToolsCard(
                readerTheme: readerTheme,
                connectedMode: connectedMode,
                onSearch: onSearch,
                onIndex: onIndex,
                onSettings: onSettings,
                onSaveSurah: onSaveSurah,
                onToggleConnectedMode: onToggleConnectedMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.readerTheme,
    required this.onTap,
  });

  final QuranReaderTheme readerTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17.r),
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: readerTheme.controlsBackgroundColor,
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 14,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: readerTheme.controlsTextColor,
          size: 24.sp,
        ),
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  const _ToolsCard({
    required this.readerTheme,
    required this.connectedMode,
    required this.onSearch,
    required this.onIndex,
    required this.onSettings,
    required this.onSaveSurah,
    required this.onToggleConnectedMode,
  });

  final QuranReaderTheme readerTheme;
  final bool connectedMode;

  final VoidCallback onSearch;
  final VoidCallback onIndex;
  final VoidCallback onSettings;
  final VoidCallback onSaveSurah;
  final VoidCallback onToggleConnectedMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: readerTheme.controlsBackgroundColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: readerTheme.dividerColor.withOpacity(0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 14,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButtonOnly(
            icon: connectedMode
                ? Icons.menu_book_rounded
                : Icons.article_outlined,
            tooltip: connectedMode ? 'متصل' : 'مصحف',
            readerTheme: readerTheme,
            onTap: onToggleConnectedMode,
          ),
          _IconLabelButton(
            icon: Icons.search_rounded,
            label: 'بحث',
            readerTheme: readerTheme,
            onTap: onSearch,
          ),
          _IconLabelButton(
            icon: Icons.format_list_bulleted_rounded,
            label: 'فهرس',
            readerTheme: readerTheme,
            onTap: onIndex,
          ),
          _IconLabelButton(
            icon: Icons.tune_rounded,
            label: 'إعدادات',
            readerTheme: readerTheme,
            onTap: onSettings,
          ),
          _IconButtonOnly(
            icon: Icons.bookmark_add_outlined,
            tooltip: 'حفظ الموضع',
            readerTheme: readerTheme,
            onTap: onSaveSurah,
          ),
        ],
      ),
    );
  }
}

class _IconLabelButton extends StatelessWidget {
  const _IconLabelButton({
    required this.icon,
    required this.label,
    required this.readerTheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final QuranReaderTheme readerTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: SizedBox(
        width: 43.w,
        height: 40.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: readerTheme.controlsTextColor,
              size: 18.sp,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 8.sp,
                fontWeight: FontWeight.w900,
                color: readerTheme.controlsTextColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButtonOnly extends StatelessWidget {
  const _IconButtonOnly({
    required this.icon,
    required this.tooltip,
    required this.readerTheme,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final QuranReaderTheme readerTheme;
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
          height: 40.h,
          child: Icon(
            icon,
            color: readerTheme.controlsTextColor,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}