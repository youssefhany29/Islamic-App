part of '../qpc_connected_mushaf_page.dart';

class _SelectionAyahTextPreview extends StatelessWidget {
  const _SelectionAyahTextPreview({
    required this.future,
    required this.readerTheme,
    required this.isLargeSheet,
  });

  final Future<QuranAyahSheetText?> future;
  final QuranReaderTheme readerTheme;
  final bool isLargeSheet;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranAyahSheetText?>(
      future: future,
      builder: (context, snapshot) {
        final QuranAyahSheetText? text = snapshot.data;
        final String displayText = text?.hafsText.trim().isNotEmpty == true
            ? text!.hafsText
            : text?.plainText ?? '';

        if (displayText.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isLargeSheet ? 12 : 12.w,
            vertical: isLargeSheet ? 8 : 9.h,
          ),
          decoration: BoxDecoration(
            color: readerTheme.pageBackground.withOpacity(
              readerTheme.isDarkLike ? 0.38 : 0.68,
            ),
            borderRadius: BorderRadius.circular(isLargeSheet ? 13 : 16.r),
            border: Border.all(
              color: readerTheme.dividerColor.withOpacity(0.55),
            ),
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: text?.hasHafsText == true ? 'quran' : 'cairo',
              fontSize: isLargeSheet ? 17 : 19.sp,
              height: 1.75,
              fontWeight: FontWeight.w500,
              color: readerTheme.textColor,
            ),
          ),
        );
      },
    );
  }
}

class _SelectionActionTile extends StatelessWidget {
  const _SelectionActionTile({
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

    return Padding(
      padding: EdgeInsets.only(bottom: isLargeSheet ? 6 : 8.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(isLargeSheet ? 13 : 16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeSheet ? 10 : 12.w,
            vertical: isLargeSheet ? 8 : 12.w,
          ),
          decoration: BoxDecoration(
            color: readerTheme.controlsBackgroundColor.withOpacity(
              readerTheme.isDarkLike ? 0.35 : 0.07,
            ),
            borderRadius: BorderRadius.circular(isLargeSheet ? 13 : 16.r),
            border: Border.all(color: readerTheme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: readerTheme.selectedWordTextColor,
                size: isLargeSheet ? 18 : 24.sp,
              ),
              SizedBox(width: isLargeSheet ? 9 : 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: isLargeSheet ? 10.5 : 13.sp,
                        fontWeight: FontWeight.w900,
                        color: readerTheme.textColor,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: isLargeSheet ? 1 : 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: isLargeSheet ? 9 : 11.sp,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: readerTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
