import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
import 'package:islamic_app/features/memorization/presentation/pages/memorization_training_session_page.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_data.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/review_schedule/review_schedule_board_card.dart';
import 'package:islamic_app/features/memorization/test/pages/memorization_test_session_page.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';

import '../widgets/analytics/analytics_ui.dart';

class MemorizationReviewSchedulePage extends StatefulWidget {
  const MemorizationReviewSchedulePage({super.key});

  @override
  State<MemorizationReviewSchedulePage> createState() =>
      _MemorizationReviewSchedulePageState();
}

class _MemorizationReviewSchedulePageState
    extends State<MemorizationReviewSchedulePage> {
  late Future<ReviewScheduleData> pageFuture;
  late PageController monthController;

  int selectedMonthIndex = 0;
  DateTime? selectedDay;
  bool isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    pageFuture = ReviewScheduleData.load();
    monthController = PageController();
  }

  @override
  void dispose() {
    monthController.dispose();
    super.dispose();
  }

  void _refreshPage() {
    if (!mounted) return;

    setState(() {
      pageFuture = ReviewScheduleData.load();
    });
  }

  void _selectDay(DateTime day) {
    setState(() => selectedDay = day);
  }

  void _clearDaySelection() {
    setState(() => selectedDay = null);
  }

  void _toggleCalendar() {
    setState(() => isCalendarExpanded = !isCalendarExpanded);
  }

  void _goToMonth(int index, int monthsCount) {
    final nextIndex = index.clamp(0, monthsCount - 1).toInt();
    if (nextIndex == selectedMonthIndex) return;

    setState(() {
      selectedMonthIndex = nextIndex;
      selectedDay = null;
    });

    if (monthController.hasClients) {
      monthController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMonthPageChanged(int index) {
    setState(() {
      selectedMonthIndex = index;
      selectedDay = null;
    });
  }

  Future<void> _openTask(ReviewScheduleItem item) async {
    if (!item.task.hasValidRange) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => item.task.type == 'selfTest'
            ? MemorizationTestSessionPage(task: item.task)
            : MemorizationTrainingSessionPage(task: item.task),
      ),
    );

    if (result == true) _refreshPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pageBackground = AnalyticsThemeColors.pageBackground(context);

    final appBarTheme = theme.copyWith(
      colorScheme: colors.copyWith(
        background: pageBackground,
        surface: Colors.white,
      ),
      iconTheme: theme.iconTheme.copyWith(color: Colors.white),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      textTheme: theme.textTheme.copyWith(
        headlineLarge: theme.textTheme.headlineLarge?.copyWith(
          color: Colors.white,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Theme(
              data: appBarTheme,
              child: const CustomAppBar(
                category: CustomAppBarCategory(text: 'جدول المراجعة'),
              ),
            ),
            Expanded(
              child: FutureBuilder<ReviewScheduleData>(
                future: pageFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                      child: const _ReviewScheduleLoadingCard(),
                    );
                  }

                  if (data == null || !data.hasActivePlan || data.months.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                      child: _ReviewScheduleEmptyCard(
                        plansCount: data?.plansCount ?? 0,
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.fromLTRB(0, 10.h, 0, 0),
                    child: ReviewScheduleBoardCard(
                      months: data.months,
                      selectedMonthIndex: selectedMonthIndex,
                      monthController: monthController,
                      isCalendarExpanded: isCalendarExpanded,
                      selectedDay: selectedDay,
                      onMonthChanged: _onMonthPageChanged,
                      onToggleCalendar: _toggleCalendar,
                      onPreviousMonth: () => _goToMonth(
                        selectedMonthIndex - 1,
                        data.months.length,
                      ),
                      onNextMonth: () => _goToMonth(
                        selectedMonthIndex + 1,
                        data.months.length,
                      ),
                      onDaySelected: _selectDay,
                      onClearDaySelection: _clearDaySelection,
                      onTaskTap: _openTask,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewScheduleLoadingCard extends StatelessWidget {
  const _ReviewScheduleLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 172.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 0.9.w,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.4.w,
            valueColor: AlwaysStoppedAnimation<Color>(
              colors.onPrimary.withOpacity(0.78),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewScheduleEmptyCard extends StatelessWidget {
  const _ReviewScheduleEmptyCard({required this.plansCount});

  final int plansCount;

  @override
  Widget build(BuildContext context) {
    final textColor = AnalyticsThemeColors.textPrimary(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(15.w, 17.h, 15.w, 17.h),
      decoration: AnalyticsDecorations.outerCard(context, radius: 24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'لا توجد خطة نشطة',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.body(context).copyWith(
              color: textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            plansCount == 0
                ? 'أنشئ خطة أولًا حتى يظهر جدول الحفظ والمراجعة.'
                : 'استرجع خطة متوقفة أو أنشئ خطة جديدة لعرض الجدول.',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(
              color: textColor.withOpacity(0.58),
              fontSize: 9.2.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
