import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DailyChangeContainer extends StatelessWidget {
  const DailyChangeContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: 272.w,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 5),
              child: Text(
                'ذكر اليوم',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SizedBox(height: 5.h,),
            Center(
              child: Container(
                width: 210.w,
                height: 60.h,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            SizedBox(height: 25.h,),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'دعاء اليوم',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SizedBox(height: 5.h,),
            Center(
              child: Container(
                width: 210.w,
                height: 60.h,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            SizedBox(height: 25.h,),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'خاطرة اليوم',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SizedBox(height: 5.h,),
            Center(
              child: Container(
                width: 210.w,
                height: 60.h,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            SizedBox(height: 10.h,)
          ],
        ),
      ),
    );
  }
}

class DailyChangeCategory{
  final String text;
  DailyChangeCategory({required this.text});
}