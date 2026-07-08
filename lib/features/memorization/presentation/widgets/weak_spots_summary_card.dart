import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../pages/memorization_weak_spots_page.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_weak_spots_engine.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
class WeakSpotsSummaryCard extends StatefulWidget {
  const WeakSpotsSummaryCard({super.key});

  @override
  State<WeakSpotsSummaryCard> createState() => _WeakSpotsSummaryCardState();
}

class _WeakSpotsSummaryCardState extends State<WeakSpotsSummaryCard> {
  Future<List<MemorizationWeakSpotModel>>? weakSpotsFuture;

  @override
  void initState() {
    super.initState();
    weakSpotsFuture = const MemorizationWeakSpotsEngine().getWeakSpots();
  }

  Future<void> _openWeakSpots(BuildContext context) async {
    AppHaptics.tap(context);

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const MemorizationWeakSpotsPage(),
      ),
    );

    if (!mounted) return;

    setState(() {
      weakSpotsFuture = const MemorizationWeakSpotsEngine().getWeakSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<MemorizationWeakSpotModel>>(
      future: weakSpotsFuture,
      builder: (context, snapshot) {
        final weakSpots = snapshot.data ?? const <MemorizationWeakSpotModel>[];
        final forgottenCount = weakSpots.where((item) => item.isForgotten).length;
        final hardCount = weakSpots.length - forgottenCount;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24.r),
            onTap: () => _openWeakSpots(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.13),
                ),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      weakSpots.isEmpty
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: theme.colorScheme.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'مواضعي الضعيفة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                            color: theme.colorScheme.surface
),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          weakSpots.isEmpty
                              ? 'لا توجد مواضع ضعيفة نشطة الآن. أي موضع صعب سيظهر هنا تلقائيًا.'
                              : '$hardCount صعب • $forgottenCount منسي • اضغط لبدء إنقاذ مباشر.',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w600,
                            color: theme.colorScheme.surface.withOpacity(0.58),
                            height: 1.4
),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      '${weakSpots.length}',
                      style: AppTextStyles.caption(context).copyWith(
fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        height: 1
),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.surface.withOpacity(0.45),
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
