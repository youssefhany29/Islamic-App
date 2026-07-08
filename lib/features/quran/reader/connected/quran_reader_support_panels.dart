part of '../qpc_connected_mushaf_page.dart';

class _QpcManualPageInfoHeader extends StatelessWidget {
  const _QpcManualPageInfoHeader({
    required this.readerTheme,
    required this.surahLabel,
    required this.surahCount,
    required this.juzNumber,
    required this.pageNumber,
    required this.isLargeScreen,
  });

  final QuranReaderTheme readerTheme;
  final String surahLabel;
  final int surahCount;
  final int juzNumber;
  final int pageNumber;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    final String trimmedSurah = surahLabel.trim();
    final String surahPrefix = surahCount > 1 ? 'سور' : 'سورة';
    final String surahText = trimmedSurah.isEmpty
        ? ''
        : '$surahPrefix $trimmedSurah';
    final String juzText = 'الجزء ${_qpcArabicNumber(juzNumber)}';
    final String pageText = _qpcArabicNumber(pageNumber);

    final double topInset = isLargeScreen ? 10 : 6.h;
    final double sideInset = isLargeScreen ? 22 : 16.w;
    final double bottomInset = isLargeScreen ? 2 : 7.h;
    final double maxSideWidth = isLargeScreen ? 220 : 154.w;

    final TextStyle topStyle = TextStyle(
      fontFamily: 'cairo',
      fontSize: isLargeScreen ? 10.5 : 9.2.sp,
      height: 1.15,
      fontWeight: FontWeight.w700,
      color: readerTheme.textColor.withValues(alpha: 0.66),
    );

    final TextStyle pageStyle = TextStyle(
      fontFamily: 'cairo',
      fontSize: isLargeScreen ? 11.5 : 10.4.sp,
      height: 1,
      fontWeight: FontWeight.w800,
      color: readerTheme.textColor.withValues(alpha: 0.72),
    );

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned(
            top: topInset,
            left: sideInset,
            child: SizedBox(
              width: maxSideWidth,
              child: Text(
                surahText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                textDirection: TextDirection.rtl,
                style: topStyle,
              ),
            ),
          ),
          Positioned(
            top: topInset,
            right: sideInset,
            child: SizedBox(
              width: maxSideWidth,
              child: Text(
                juzText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: topStyle,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: Center(
              child: Text(
                pageText,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: pageStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderSideToolsPanel extends StatelessWidget {
  const _ReaderSideToolsPanel({
    required this.readerTheme,
    required this.connectedMode,
    required this.hideMode,
    required this.onBack,
    required this.onSearch,
    required this.onIndex,
    required this.onSettings,
    required this.onSaveSurah,
    required this.onToggleConnectedMode,
    required this.onToggleHideMode,
  });

  final QuranReaderTheme readerTheme;
  final bool connectedMode;
  final QuranHideMode hideMode;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onIndex;
  final VoidCallback onSettings;
  final VoidCallback onSaveSurah;
  final VoidCallback onToggleConnectedMode;
  final VoidCallback onToggleHideMode;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: readerTheme.controlsBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: readerTheme.dividerColor.withOpacity(0.72)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                readerTheme.isDarkLike ? 0.26 : 0.12,
              ),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SideToolButton(
              icon: Icons.arrow_forward_rounded,
              label: 'رجوع',
              readerTheme: readerTheme,
              onTap: onBack,
            ),
            const SizedBox(height: 8),
            _SideToolButton(
              icon: connectedMode
                  ? Icons.menu_book_rounded
                  : Icons.article_outlined,
              label: connectedMode ? 'مصحف' : 'متصل',
              readerTheme: readerTheme,
              onTap: onToggleConnectedMode,
            ),
            _SideToolButton(
              icon: _hideIcon(hideMode),
              label: 'إخفاء',
              readerTheme: readerTheme,
              onTap: onToggleHideMode,
            ),
            _SideToolButton(
              icon: Icons.search_rounded,
              label: 'بحث',
              readerTheme: readerTheme,
              onTap: onSearch,
            ),
            _SideToolButton(
              icon: Icons.format_list_bulleted_rounded,
              label: 'فهرس',
              readerTheme: readerTheme,
              onTap: onIndex,
            ),
            _SideToolButton(
              icon: Icons.tune_rounded,
              label: 'إعدادات',
              readerTheme: readerTheme,
              onTap: onSettings,
            ),
            _SideToolButton(
              icon: Icons.bookmark_add_outlined,
              label: 'حفظ',
              readerTheme: readerTheme,
              onTap: onSaveSurah,
            ),
          ],
        ),
      ),
    );
  }

  IconData _hideIcon(QuranHideMode mode) {
    switch (mode) {
      case QuranHideMode.visible:
        return Icons.visibility_rounded;
      case QuranHideMode.partial:
        return Icons.visibility_off_rounded;
      case QuranHideMode.full:
        return Icons.blur_on_rounded;
    }
  }
}

class _SideToolButton extends StatelessWidget {
  const _SideToolButton({
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
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: readerTheme.controlsTextColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: readerTheme.controlsTextColor, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: readerTheme.controlsTextColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedReadingStatusBar extends StatelessWidget {
  const _ConnectedReadingStatusBar({
    required this.visible,
    required this.readerTheme,
    required this.surahName,
    required this.ayahNumber,
    required this.juzNumber,
  });

  final bool visible;
  final QuranReaderTheme readerTheme;
  final String surahName;
  final int ayahNumber;
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    final EdgeInsets padding = isLargeScreen
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
        : EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h);

    final double radius = isLargeScreen ? 14 : 18.r;
    final double fontSize = isLargeScreen ? 9.5 : 9.8.sp;
    final double blurRadius = isLargeScreen ? 10 : 12;
    final Offset shadowOffset = isLargeScreen
        ? const Offset(0, 3)
        : Offset(0, 4.h);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: readerTheme.controlsBackgroundColor.withOpacity(0.94),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: readerTheme.dividerColor.withOpacity(0.62),
                width: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    readerTheme.isDarkLike ? 0.20 : 0.08,
                  ),
                  blurRadius: blurRadius,
                  offset: shadowOffset,
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'سورة $surahName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: _textStyle(fontSize),
                  ),
                ),
                _Dot(readerTheme: readerTheme),
                Text(
                  'آية ${_arabicNumber(ayahNumber)}',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: _textStyle(fontSize),
                ),
                _Dot(readerTheme: readerTheme),
                Text(
                  'الجزء ${_arabicNumber(juzNumber)}',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: _textStyle(fontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _textStyle(double fontSize) {
    return TextStyle(
      fontFamily: 'cairo',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: readerTheme.controlsTextColor,
      height: 1.05,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.readerTheme});

  final QuranReaderTheme readerTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '•',
        style: TextStyle(
          fontFamily: 'cairo',
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: readerTheme.controlsTextColor.withOpacity(0.55),
          height: 1,
        ),
      ),
    );
  }
}
