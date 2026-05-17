import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/App%20Main%20Screens%20Components/custom_app_bar.dart';
import 'package:islamic_app/Common%20Components/SquareLogo.dart';

class Ahadethpage extends StatelessWidget {
  const Ahadethpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          CustomAppBar(category: CustomAppBarCategory(text: 'أحاديث')),
          SizedBox(height: 16.h,),
          SquareLogo(category: SquareLogoCategory(image: 'assets/icons/boook.png'),)
        ],
      ),
    );
  }
}
