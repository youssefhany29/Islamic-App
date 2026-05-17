import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/Common%20Components/SquareLogo.dart';

class NightPrayPage extends StatelessWidget {
  const NightPrayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          CustomAppBar(category: CustomAppBarCategory(text: 'قيام الليل')),
          SizedBox(height: 16.h,),
          SquareLogo(category: SquareLogoCategory(image: 'assets/icons/prayerMat.png'))
        ],
      ),
    );
  }
}
