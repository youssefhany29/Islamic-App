import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class MemorizationHelpButton extends StatelessWidget {
  const MemorizationHelpButton({
    super.key,
    this.heroStyle = false,
  });

  final bool heroStyle;

  void _openHelpSheet(BuildContext context) {
    AppHaptics.tap(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final topSafe = MediaQuery.of(context).padding.top;

        return Padding(
          padding: EdgeInsets.only(top: topSafe + 12.h),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.86,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26.r),
                  ),
                ),
                child: _MemorizationHelpSheet(
                  scrollController: scrollController,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color backgroundColor = heroStyle
        ? Colors.white.withOpacity(0.15)
        : theme.colorScheme.primary.withOpacity(0.12);

    final Color borderColor = heroStyle
        ? Colors.white.withOpacity(0.24)
        : theme.colorScheme.primary.withOpacity(0.22);

    final Color iconColor = heroStyle ? Colors.white : theme.colorScheme.primary;

    final BorderRadius radius = BorderRadius.circular(14.r);

    return SizedBox(
      width: 38.w,
      height: 38.w,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () => _openHelpSheet(context),
            child: Center(
              child: Icon(
                Icons.help_outline_rounded,
                color: iconColor,
                size: 21.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemorizationHelpSheet extends StatelessWidget {
  const _MemorizationHelpSheet({
    this.scrollController,
  });

  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'كيف تعمل حلقة الحفظ؟',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  height: 1.25
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'النظام الآن مبني على خطة نشطة واحدة فقط حتى لا يتشتت المستخدم. يمكن إيقاف الخطة أو استرجاع خطة متوقفة بدون مسح التقدم.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.surface.withOpacity(0.64),
                  height: 1.55
              ),
            ),
            SizedBox(height: 16.h),
            const _HelpStep(
              number: '١',
              title: 'الخطة الحالية',
              subtitle:
              'يكون للمستخدم خطة نشطة واحدة فقط، مثل حفظ سورة البقرة أو مراجعة جزء عم. إنشاء خطة جديدة يوقف الحالية ولا يمسح تقدمها.',
              icon: Icons.track_changes_rounded,
            ),
            const _HelpStep(
              number: '٢',
              title: 'مهمة اليوم',
              subtitle:
              'التطبيق يجهز مهمة واضحة من الخطة: حفظ جديد أو مراجعة. المهمة تفتح القرآن على نفس السورة أو المقطع المطلوب.',
              icon: Icons.today_rounded,
            ),
            const _HelpStep(
              number: '٣',
              title: 'جلسة الإتقان',
              subtitle:
              'المستخدم يقرأ المقطع، يراجع، ثم يختبر نفسه مرة واحدة فقط حتى لا يتحول الاختبار إلى تكرار عشوائي.',
              icon: Icons.school_rounded,
            ),
            const _HelpStep(
              number: '٤',
              title: 'التقييم الذكي',
              subtitle:
              'بعد الاختبار يقيّم حفظه: سهل، جيد، صعب، أو نسيت. التقييم هو الذي يحدد هل المقطع يرجع قريبًا أم يتباعد.',
              icon: Icons.fact_check_rounded,
            ),
            const _HelpStep(
              number: '٥',
              title: 'تقويم المراجعة',
              subtitle:
              'لو اختار صعب أو نسيت، يظهر المقطع في التقويم كمراجعات قريبة ١ / ٣ / ٧ / ١٥ / ٣٠ يوم. هذا للضعيف والجديد فقط، وليس لكل القرآن.',
              icon: Icons.calendar_month_rounded,
            ),
            const _HelpStep(
              number: '٦',
              title: 'الخطط المتوقفة',
              subtitle:
              'أي خطة يتم إيقافها تبقى محفوظة في قسم الخطط المتوقفة. يمكن استرجاعها لاحقًا بدل ضياع التقدم.',
              icon: Icons.inventory_2_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
                Positioned(
                  top: 2.h,
                  right: 4.w,
                  child: Text(
                    number,
                    style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.surface,
                      height: 1.25
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.surface.withOpacity(0.60),
                      height: 1.48
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
