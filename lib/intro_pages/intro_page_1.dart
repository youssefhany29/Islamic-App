import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'intro_page_2.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 30.h,
              ),
              Text('ديني في جيبي',style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily:'cairo'),),
              SizedBox(
                height: 50.h,
              ),
              Text('أهلا بكم في تطبيق ديني في جيبي',style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily:'cairo'),),
              SizedBox(
                height: 50.h,
              ),
              Container(
                width: 272.w,
                height: 272.h,
                child: Lottie.asset('assets/animation/Animation - 1748091415849.json',
                repeat: true),
              ),
              SizedBox(height: 40.h,),
              SizedBox(
                width: 272.w,
                height: 40.h,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,

                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => IntroPage2()));
                  },
                  child: Text(
                    'التالي',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
