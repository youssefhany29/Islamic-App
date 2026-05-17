// row_following_components.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RowFollowingComponents extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  const RowFollowingComponents({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(width: 2.w),
              Checkbox(
                value: value,
                onChanged: (newVal) => onChanged(newVal ?? false),
                shape: CircleBorder(),
                checkColor: Colors.green,
                activeColor: Colors.white,
                fillColor: MaterialStateProperty.all(Colors.white),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Center(
          child: Divider(
            color: Colors.white70,
            thickness: 0.5.h,
            indent: 20.w,
            endIndent: 20.w,
          ),
        ),
      ],
    );
  }
}
