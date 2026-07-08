import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/shared/widgets/common_components/app_layout_constants.dart';

class PhoneQuranPageContent extends StatelessWidget {
  const PhoneQuranPageContent({
    super.key,
    required this.heroCard,
    required this.quickAccessCard,
    required this.readingSummaryCard,
    required this.toolsCard,
    required this.dailyAyahCard,
  });

  final Widget heroCard;
  final Widget quickAccessCard;
  final Widget readingSummaryCard;
  final Widget toolsCard;
  final Widget dailyAyahCard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AppLayoutConstants.pageHorizontalPadding,
      ).copyWith(bottom: 96.h),
      child: Column(
        children: [
          heroCard,
          SizedBox(height: 10.h),
          quickAccessCard,
          SizedBox(height: 14.h),
          readingSummaryCard,
          SizedBox(height: 14.h),
          toolsCard,
          SizedBox(height: 14.h),
          dailyAyahCard,
          SizedBox(height: 14.h),
        ],
      ),
    );
  }
}
