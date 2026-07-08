import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

import 'package:islamic_app/features/night_pray/presentation/widgets/following_night_pray.dart';
import 'package:islamic_app/features/night_pray/presentation/widgets/night_pray_info_card.dart';

class NightPrayPage extends StatelessWidget {
  const NightPrayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(
        category: CustomAppBarCategory(
          text: 'قيام الليل',
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayoutConstants.pageHorizontalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width >= 600
                      ? 760
                      : AppLayoutConstants.mainCardWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: EdgeInsets.all(
                          MediaQuery.sizeOf(context).width >= 600 ? 12 : 10.w,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(22.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.24),
                              blurRadius: 18.r,
                              offset: Offset(0, 8.h),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const NightPrayInfoCard(
                              title: 'قيام الليل',
                              subtitle:
                                  'يبدأ من بعد صلاة العشاء إلى طلوع الفجر. ابدأ بركعتين خفيفتين، ثم الوتر إن لم تكن صليته.',
                              icon: Icons.nights_stay_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const FollowingNightPray(),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
