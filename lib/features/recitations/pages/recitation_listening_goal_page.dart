import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../services/recitation_listening_stats_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';

class RecitationListeningGoalPage extends StatefulWidget {
  const RecitationListeningGoalPage({super.key});

  @override
  State<RecitationListeningGoalPage> createState() =>
      _RecitationListeningGoalPageState();
}

class _RecitationListeningGoalPageState
    extends State<RecitationListeningGoalPage> {
  final TextEditingController customGoalController = TextEditingController();

  int selectedMinutes = 20;
  bool isSaving = false;

  final List<int> suggestedGoals = const [5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  @override
  void dispose() {
    customGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final seconds = await RecitationListeningStatsStorage.getDailyGoalSeconds();
    final minutes = (seconds / 60).round();

    if (!mounted) return;

    setState(() {
      selectedMinutes = minutes;
      customGoalController.text = minutes.toString();
    });
  }

  Future<void> _saveGoal() async {
    AppHaptics.tap(context);

    final customMinutes =
        int.tryParse(customGoalController.text.trim()) ?? selectedMinutes;
    final safeMinutes = customMinutes.clamp(1, 180).toInt();

    setState(() {
      isSaving = true;
    });

    await RecitationListeningStatsStorage.setDailyGoalMinutes(safeMinutes);

    if (!mounted) return;

    setState(() {
      isSaving = false;
      selectedMinutes = safeMinutes;
      customGoalController.text = safeMinutes.toString();
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          'تم حفظ هدف الاستماع اليومي',
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Column(
            children: [
              _Header(
                title: 'هدف الاستماع اليومي',
                onBack: () {
                  AppHaptics.tap(context);
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22.r,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.track_changes_rounded,
                                    color: primary,
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    'اختر وردك اليومي من الاستماع للقرآن',
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'الهدف هنا بالدقائق، والتطبيق يحسب تقدمك تلقائيًا أثناء تشغيل التلاوة.',
                              textAlign: TextAlign.right,
                              style: AppTextStyles.caption(context).copyWith(
                                height: 1.6,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        alignment: WrapAlignment.end,
                        children: suggestedGoals.map((minutes) {
                          final selected = selectedMinutes == minutes;

                          return ChoiceChip(
                            selected: selected,
                            label: Text(
                              '$minutes دقيقة',
                              style: AppTextStyles.caption(context).copyWith(
                                color: selected ? Colors.white : textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            selectedColor: primary,
                            backgroundColor: primary.withOpacity(0.10),
                            side: BorderSide(
                              color: selected
                                  ? primary
                                  : textColor.withOpacity(0.08),
                            ),
                            onSelected: (_) {
                              AppHaptics.tap(context);
                              setState(() {
                                selectedMinutes = minutes;
                                customGoalController.text = minutes.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 14.h),
                      TextField(
                        controller: customGoalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'هدف مخصص بالدقائق',
                          labelStyle: TextStyle(
                            fontFamily: 'cairo',
                            color: textColor.withOpacity(0.60),
                          ),
                          filled: true,
                          fillColor: primary.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: AppTextStyles.caption(context).copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                        onChanged: (value) {
                          final minutes = int.tryParse(value.trim());

                          if (minutes != null) {
                            setState(() {
                              selectedMinutes = minutes.clamp(1, 180).toInt();
                            });
                          }
                        },
                      ),
                      SizedBox(height: 22.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveGoal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          child: Text(
                            isSaving ? 'جاري الحفظ...' : 'حفظ الهدف',
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 38.w, minHeight: 38.h),
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18.sp,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.headline(
                context,
              ).copyWith(fontWeight: FontWeight.w900, color: textColor),
            ),
          ),
          SizedBox(width: 38.w),
        ],
      ),
    );
  }
}
