part of 'daily_wird_page.dart';

class _LargePageTitle extends StatelessWidget {
  const _LargePageTitle({required this.title, required this.onBack});

  final String title;
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
              title,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onBackground,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RoundBackButton(onTap: onBack),
        ],
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
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
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final VoidCallback onCreateKhatma;

  const _PageHeader({
    required this.activeCount,
    required this.completedCount,
    required this.onCreateKhatma,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLargeScreen ? 14 : 16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(isLargeScreen ? 22 : 22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'متابعة الأوراد والختمات',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 6 : 8.h),
          SizedBox(
            width: double.infinity,
            child: Text(
              'أنشئ أكثر من ورد، وتابع تقدم كل ختمة بشكل مستقل.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: isLargeScreen ? 2 : null,
              overflow: isLargeScreen ? TextOverflow.ellipsis : null,
              style: AppTextStyles.caption(
                context,
              ).copyWith(height: 1.35, color: Colors.white.withOpacity(0.82)),
            ),
          ),
          SizedBox(height: isLargeScreen ? 12 : 14.h),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _HeaderMiniBox(
                  title: 'أوراد نشطة',
                  value: activeCount.toString().toArabicNumbers,
                ),
              ),
              SizedBox(width: isLargeScreen ? 8 : 10.w),
              Expanded(
                child: _HeaderMiniBox(
                  title: 'مكتملة',
                  value: completedCount.toString().toArabicNumbers,
                ),
              ),
            ],
          ),
          SizedBox(height: isLargeScreen ? 12 : 14.h),
          SizedBox(
            width: double.infinity,
            height: isLargeScreen ? 36 : 40.h,
            child: ElevatedButton.icon(
              onPressed: onCreateKhatma,
              icon: Icon(
                Icons.add_rounded,
                size: isLargeScreen ? 16 : 18.sp,
                color: Colors.black87,
              ),
              label: Text(
                'إنشاء ورد جديد',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 10.5 : 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isLargeScreen ? 15 : 15.r,
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

class _HeaderMiniBox extends StatelessWidget {
  final String title;
  final String value;

  const _HeaderMiniBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return SizedBox(
      height: isLargeScreen ? 48 : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isLargeScreen ? 5 : 10.h,
          horizontal: isLargeScreen ? 6 : 0,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(isLargeScreen ? 14 : 14.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 8 : 9.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(height: isLargeScreen ? 3 : 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: isLargeScreen ? 11 : 14.sp,
                  fontWeight: FontWeight.w900,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: TextDirection.rtl,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: _MainPageTypographySizes.cardTitle(context),
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onBackground,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(height: isLargeScreen ? 3 : 3.h),
              SizedBox(
                width: double.infinity,
                child: Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: _MainPageTypographySizes.cardSubtitle(context),
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground.withOpacity(0.55),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
