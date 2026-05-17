import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/MainPage/Components%20Main%20Page/videos%20widgets/video_componets.dart';


class AppVideoWidget extends StatelessWidget {
  const AppVideoWidget({super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272.w,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VideoComponents(
            onTap: () {  },
            category: Category(
                image: 'assets/icons/videoEdition.png',
                text: 'فيديوهات'
            ),
          ),
          VideoComponents(
            onTap: () {  },
            category: Category(
                image: 'assets/icons/porcaster.png',
                text: 'بودكاست'
            ),
          )
        ],
      ),
    );
  }
}

