import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'row_following_components.dart';

class FollowingPray extends StatefulWidget {
  const FollowingPray({super.key});

  @override
  State<FollowingPray> createState() => _FollowingPrayState();
}

class _FollowingPrayState extends State<FollowingPray> {
  final List<String> _prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  late List<bool> _checked;
  int _dayCount = 0;

  @override
  void initState() {
    super.initState();
    _checked = List<bool>.filled(_prayers.length, false);
  }

  void _onCheckboxChanged(int index, bool newVal) {
    setState(() {
      _checked[index] = newVal;
      if (_checked.every((v) => v)) {
        // زوّد يوم مكتمل ورجع الـ checkboxes كلها false
        _dayCount++;
        _checked = List<bool>.filled(_prayers.length, false);
      }
    });
  }

  void _resetDays() {
    setState(() {
      _dayCount = 0;
      _checked = List<bool>.filled(_prayers.length, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int count = _checked.where((v) => v).length;
    final int total = _checked.length;

    return Container(
      width: 272.w,
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.refresh,
                    color: Theme.of(context).colorScheme.onPrimary),
                onPressed: _resetDays,
              ),

              // العنوان
              Padding(
                padding: EdgeInsets.only(top: 5.h, right: 20.w),
                child: Text(
                  'تتبع صلاتك',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          for (int i = 0; i < _prayers.length; i++)
            RowFollowingComponents(
              text: _prayers[i],
              value: _checked[i],
              onChanged: (newVal) => _onCheckboxChanged(i, newVal),
            ),
          SizedBox(height: 20.h),
          Center(
            child: Container(
              width: 252.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'تقدم اليوم $count / $total',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Center(
            child: Container(
              width: 252.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'أيام متتالية: $_dayCount',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
