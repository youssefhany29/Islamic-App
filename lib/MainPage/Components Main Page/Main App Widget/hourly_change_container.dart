import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../App Main Screens/Zekr Page/Zekr secondary Pages/evening_zekr.dart';
import '../../../App Main Screens/Zekr Page/Zekr secondary Pages/morning_zekr.dart';



class HourlyChangeContainer extends StatefulWidget {
  const HourlyChangeContainer({super.key});

  @override
  State<HourlyChangeContainer> createState() => _HourlyChangeContainerState();
}

class _HourlyChangeContainerState extends State<HourlyChangeContainer> {
  late bool isMorning;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now();
    if (now.hour >= 6 && now.hour < 18) {
      isMorning = true;
    } else {
      isMorning = false;
    }
  }

  void _onTap() {
    if (isMorning) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MorningZekr()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EveningZekr()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            color: Theme.of(context).colorScheme.secondary,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            )
          ),
          width: 272.w,
          padding: EdgeInsets.symmetric(vertical: 5.h),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isMorning
                      ? 'أذكار الصباح'
                      : 'أذكار المساء',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: 13.w,),
                Icon(
                    Icons.add_alarm_outlined,
                    color: Theme.of(context).colorScheme.surface,
                  size: 15.sp,
                ),
                SizedBox(width: 15.w,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
