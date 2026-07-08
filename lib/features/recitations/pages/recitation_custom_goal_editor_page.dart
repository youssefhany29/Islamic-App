import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../models/recitation_custom_goal_model.dart';
import '../services/recitation_custom_goals_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class RecitationCustomGoalEditorPage extends StatefulWidget {
  const RecitationCustomGoalEditorPage({super.key});

  @override
  State<RecitationCustomGoalEditorPage> createState() =>
      _RecitationCustomGoalEditorPageState();
}

class _RecitationCustomGoalEditorPageState
    extends State<RecitationCustomGoalEditorPage> {
  RecitationCustomGoalType selectedType =
      RecitationCustomGoalType.dailyListeningMinutes;

  late final TextEditingController targetController;

  @override
  void initState() {
    super.initState();

    targetController = TextEditingController(
      text: selectedType.info.defaultTarget.toString(),
    );
  }

  @override
  void dispose() {
    targetController.dispose();
    super.dispose();
  }

  void _changeType(RecitationCustomGoalType type) {
    AppHaptics.tap(context);

    setState(() {
      selectedType = type;
      targetController.text = type.info.defaultTarget.toString();
    });
  }

  Future<void> _saveGoal() async {
    AppHaptics.tap(context);

    final target = int.tryParse(targetController.text.trim()) ?? 0;

    if (target <= 0) {
      _showSnackBar('اكتب رقم صحيح للهدف');
      return;
    }

    final info = selectedType.info;

    final goal = RecitationCustomGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: info.title,
      type: selectedType,
      targetValue: target,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await RecitationCustomGoalsStorage.addGoal(goal);

    if (!mounted) return;

    _showSnackBar('تم إضافة الهدف الشخصي');

    Navigator.pop(context, true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 18.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.caption(
            context,
          ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primary = Theme.of(context).colorScheme.primary;
    final info = selectedType.info;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 38.w,
                        minHeight: 38.h,
                      ),
                      onPressed: () {
                        AppHaptics.tap(context);
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.sp,
                        color: textColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'إضافة هدف شخصي',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.headline(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 38.w),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff171B26),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 0.8.w,
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            CircleAvatar(
                              radius: 20.r,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              child: Icon(
                                info.icon,
                                color: const Color(0xff21C58E),
                                size: 21.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    info.title,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    info.description,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.62),
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'اختر نوع الهدف',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900, color: textColor),
                    ),
                    SizedBox(height: 8.h),
                    ...RecitationCustomGoalType.values.map(
                      (type) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _GoalTypeTile(
                          type: type,
                          selected: type == selectedType,
                          onTap: () => _changeType(type),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'قيمة الهدف',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900, color: textColor),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 50.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: primary.withOpacity(0.16)),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: targetController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'اكتب الرقم',
                                hintStyle: AppTextStyles.caption(
                                  context,
                                ).copyWith(color: textColor.withOpacity(0.45)),
                              ),
                              style: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            info.unit,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: textColor.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Material(
                      color: const Color(0xff171B26),
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14.r),
                        onTap: _saveGoal,
                        child: SizedBox(
                          width: double.infinity,
                          height: 42.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection: TextDirection.rtl,
                            children: [
                              Icon(
                                Icons.add_task_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'إضافة الهدف',
                                style: AppTextStyles.caption(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalTypeTile extends StatelessWidget {
  final RecitationCustomGoalType type;
  final bool selected;
  final VoidCallback onTap;

  const _GoalTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = type.info;

    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary
          : const Color(0xff171B26),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected
                  ? const Color(0xff21C58E)
                  : Colors.white.withOpacity(0.12),
              width: 0.8.w,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                info.icon,
                color: selected ? const Color(0xff21C58E) : Colors.white70,
                size: 19.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      info.title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      info.description,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.60),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
