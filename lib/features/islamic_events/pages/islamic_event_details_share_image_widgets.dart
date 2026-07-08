part of 'islamic_event_details_page.dart';

class _ShareImageCard extends StatelessWidget {
  const _ShareImageCard({
    required this.title,
    required this.greeting,
    required this.imageBackgroundPath,
    required this.pickedBackgroundFile,
    required this.colorBackground,
    required this.backgroundMode,
    required this.shareTextIsWhite,
    required this.shareFontSize,
    required this.titleGreetingSpacing,
  });

  final String title;
  final String greeting;
  final String imageBackgroundPath;
  final File? pickedBackgroundFile;
  final Color colorBackground;
  final _ShareBackgroundMode backgroundMode;

  final bool shareTextIsWhite;
  final double shareFontSize;
  final double titleGreetingSpacing;

  bool get _isImageMode => backgroundMode == _ShareBackgroundMode.image;

  @override
  Widget build(BuildContext context) {
    final bool large = _eventDetailsLargeScreen(context);
    final Color textColor = shareTextIsWhite ? Colors.white : Colors.black;
    final double cardWidth = large ? 300 : 290.w;
    final double cardHeight = large ? 300 : 360.h;
    final double cardRadius = large ? 24 : 26.r;
    final double cardPadding = large ? 20 : 24.w;
    final double verticalPadding = large ? 20 : 24.h;
    final double logoBox = large ? 34 : 36.w;
    final double logoPadding = large ? 5 : 5.w;
    final double titleFontSize = large
        ? (shareFontSize + 1)
        : (shareFontSize + 2).sp;
    final double greetingFontSize = large ? shareFontSize : shareFontSize.sp;
    final double spacing = large
        ? titleGreetingSpacing
        : titleGreetingSpacing.h;

    final List<Shadow> textShadows = shareTextIsWhite
        ? [Shadow(color: Colors.black.withOpacity(0.32), blurRadius: 6)]
        : [Shadow(color: Colors.white.withOpacity(0.55), blurRadius: 6)];

    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorBackground,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isImageMode && pickedBackgroundFile != null)
            Image.file(
              pickedBackgroundFile!,
              fit: BoxFit.cover,
              cacheWidth: 900,
            )
          else if (_isImageMode)
            Image.asset(imageBackgroundPath, fit: BoxFit.cover, cacheWidth: 900)
          else
            Container(color: colorBackground),

          if (!_isImageMode)
            Positioned(
              bottom: large ? 54 : 64.h,
              right: large ? -12 : -14.w,
              child: Icon(
                Icons.nightlight_round,
                color: Colors.white.withOpacity(0.09),
                size: large ? 74 : 90.sp,
              ),
            ),

          if (_isImageMode) Container(color: Colors.black.withOpacity(0.08)),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.35,
                              letterSpacing: 0,
                              shadows: textShadows,
                            ),
                          ),

                          SizedBox(height: spacing),

                          if (greeting.trim().isNotEmpty)
                            Text(
                              greeting,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: greetingFontSize,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.55,
                                letterSpacing: 0,
                                shadows: textShadows,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  width: logoBox,
                  height: logoBox,
                  padding: EdgeInsets.all(logoPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(large ? 11 : 12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/icons/koran (1).png',
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: large ? 6 : 7.h),

                Text(
                  'تذكير ومناسبات إسلامية',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: textColor.withOpacity(0.92),
                    letterSpacing: 0,
                    shadows: textShadows,
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

class _ShareActionButton extends StatelessWidget {
  const _ShareActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool large = _eventDetailsLargeScreen(context);

    final Color backgroundColor = isPrimary
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    final Color foregroundColor = isPrimary
        ? Colors.white
        : theme.colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(large ? 18 : 16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(large ? 18 : 16.r),
          splashColor: foregroundColor.withOpacity(0.10),
          highlightColor: foregroundColor.withOpacity(0.06),
          child: Container(
            height: large ? 44 : 48.h,
            padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10.w),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: large ? 20 : 17.w,
                      height: large ? 20 : 17.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: foregroundColor,
                      size: large ? 18 : 18.sp,
                    ),
                  SizedBox(width: large ? 8 : 7.w),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      locale: const Locale('ar'),
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: isPrimary
                            ? Colors.white
                            : theme.colorScheme.surface,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
