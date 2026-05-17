import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/App%20Main%20Screens/PrayerPage/pray_page.dart';
import ' hijrii_date.dart';
import '../../../App Main Screens/Ahadeth/ahadeth_page.dart';
import '../../../App Main Screens/Night Pray/night_pray_page.dart';
import '../../../App Main Screens/Zekr Page/zekr_page.dart';
import '../../../App Main Screens/kuran/index.dart';
import '../../../App Main Screens/kuran/quran_page.dart';
import 'icons_main_widget.dart';

class IconContainer extends StatelessWidget {
   IconContainer({super.key});

  final hijriArabic = HijriiDate.getTodayHijri();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 272.w,
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.all(Radius.circular(16))
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$hijriArabic',
                  style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text('ثبت عبادتك',
                  style: Theme.of(context).textTheme.headlineMedium,
                  )
                ],
              ),
            ),
            SizedBox(height: 5.h,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Theme.of(context).colorScheme.primary,
                width: 240.w,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconsMainWidget(
                        category: Category(
                            image: 'assets/icons/pray (3).png',
                            text: 'الصلاة'
                        ), onTap: () {
                           Navigator.push(
                               context, PageRouteBuilder(
                               pageBuilder: (context,animation, secondaryAnimation) => PrayPage(),
                             transitionDuration: Duration.zero,
                             reverseTransitionDuration: Duration.zero
                           ),
                         );
                      },
                      ),
                      IconsMainWidget(
                        category: Category(
                            image: 'assets/icons/QuRan.png',
                            text: 'قرآن'
                        ), onTap: () {
                        Navigator.push(
                            context, PageRouteBuilder(
                            pageBuilder: (context,animation, secondaryAnimation) => IndexPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero
                        ),
                        );
                      },
                      ),IconsMainWidget(
                        category: Category(
                            image: 'assets/icons/bead.png',
                            text: 'أذكار'
                        ), onTap: () {
                        Navigator.push(
                            context, PageRouteBuilder(
                            pageBuilder: (context,animation, secondaryAnimation) => ZekrPage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero
                        )
                        );
                      },
                      ),IconsMainWidget(
                        category: Category(
                            image: 'assets/icons/prayerMat.png',
                            text: 'قيام الليل'
                        ), onTap: () {
                        Navigator.push(
                            context, PageRouteBuilder(
                            pageBuilder: (context,animation, secondaryAnimation) => NightPrayPage(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero
                        ));
                      },
                      ),IconsMainWidget(
                        category: Category(
                            image: 'assets/icons/boook.png',
                            text: 'أحاديث'
                        ), onTap: () {
                        Navigator.push(
                            context, PageRouteBuilder(
                            pageBuilder: (context,animation, secondaryAnimation) => Ahadethpage(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero));
                      },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


