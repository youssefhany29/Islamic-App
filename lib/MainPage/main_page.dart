import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/MainPage/Components%20Main%20Page/Main%20App%20Widget/daily_change_container.dart';
import 'package:islamic_app/MainPage/Components%20Main%20Page/videos%20widgets/app_video_widget.dart';
import '../Common Components/SquareLogo.dart';
import 'Components Main Page/AppCustomBar.dart';
import 'Components Main Page/Main App Widget/hourly_change_container.dart';
import 'Components Main Page/Main App Widget/icon_container.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              AppCustomBar(),
              SizedBox(height: 16.h,),
              SquareLogo(category: SquareLogoCategory(image: 'assets/icons/BismillaH.png')),
              SizedBox(height: 16.h,),
              HourlyChangeContainer(),
              SizedBox(height: 16.h),
              IconContainer(),
              SizedBox(height: 16.h,),
              AppVideoWidget(),
              SizedBox(height: 16.h,),
              DailyChangeContainer(),
            ],
          ),
        ),
      ),
    );
  }
}

