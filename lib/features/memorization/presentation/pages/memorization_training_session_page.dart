import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import 'package:islamic_app/core/services/app_haptics.dart';

import '../../../quran/memorization/models/quran_memorization_task_model.dart';
import '../../../quran/memorization/services/quran_memorization_reader_launcher.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_primary_button.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/mastery_snack_bar.dart';
import 'package:islamic_app/features/memorization/presentation/widgets/memorization_task_progress_card.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_next_task_engine.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part 'memorization_training_session_widgets.dart';

class MemorizationTrainingSessionPage extends StatefulWidget {
  const MemorizationTrainingSessionPage({super.key, required this.task});

  final MemorizationTodayTaskModel task;

  @override
  State<MemorizationTrainingSessionPage> createState() =>
      _MemorizationTrainingSessionPageState();
}

class _MemorizationTrainingSessionPageState
    extends State<MemorizationTrainingSessionPage> {
  bool didOpenReader = false;
  bool didSelfTest = false;
  bool isSaving = false;

  String? selectedRating;
  MemorizationSessionResultModel? previousResult;

  late final DateTime startedAt;
  int progressRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    _loadPreviousResult();
  }

  Future<void> _loadPreviousResult() async {
    final result = await MemorizationSessionResultStorage.getResultByTaskId(
      widget.task.id,
    );

    if (!mounted) return;

    setState(() {
      previousResult = result;

      if (result != null) {
        didOpenReader = true;
        didSelfTest = true;
        selectedRating = result.rating;
      }
    });
  }

  bool get isAlreadyCompleted => previousResult != null;

  bool get isRescueSession => widget.task.type == 'weakReview';

  bool get isSmartTestSession => widget.task.type == 'selfTest';

  bool get canFinish {
    return !isAlreadyCompleted &&
        !isSaving &&
        didOpenReader &&
        didSelfTest &&
        selectedRating != null;
  }

  String get _sessionTitle {
    if (widget.task.type == 'dailyNew') return 'حفظ اليوم';
    if (widget.task.type == 'weakReview') return 'جلسة إنقاذ الضعيف';
    if (widget.task.type == 'selfTest')
      return widget.task.title.trim().isEmpty
          ? 'اختبار ذاتي'
          : widget.task.title;
    return 'جلسة مراجعة اليوم';
  }

  String get _mainInstruction {
    if (isAlreadyCompleted) {
      return 'تم تسجيل نتيجة هذه الجلسة بالفعل. يمكنك فتح القرآن للمراجعة فقط.';
    }

    if (isRescueSession) {
      return 'هذه جلسة إنقاذ للمقطع الصعب أو المنسي: اقرأ ببطء، كرر، اخفِ النص، ثم اختبر نفسك بصدق.';
    }

    if (isSmartTestSession) {
      return 'هذا اختبار تثبيت خفيف: افتح المقطع، اخفِ النص، حاول الاستدعاء من الذاكرة، ثم قيّم بصدق.';
    }

    if (widget.task.type == 'dailyNew') {
      return 'اقرأ المقطع بهدوء، كرره، ثم اخفِ النص واختبر نفسك مرة واحدة بتركيز.';
    }

    return 'راجع المقطع، ثم اختبر نفسك مرة واحدة بدون النظر للنص قدر الإمكان.';
  }

  Future<void> _openQuranReader() async {
    AppHaptics.tap(context);

    if (!widget.task.hasValidRange) {
      MasterySnackBar.show(context, message: 'مهمة اليوم غير جاهزة بعد');
      return;
    }

    final quranTask = QuranMemorizationTaskModel(
      id: widget.task.id,
      type: widget.task.type,
      startGlobalAyahIndex: widget.task.startGlobalAyahIndex,
      endGlobalAyahIndex: widget.task.endGlobalAyahIndex,
      title: widget.task.title,
      subtitle: widget.task.subtitle,
      estimatedMinutes: widget.task.expectedMinutes,
      dueDate: DateTime.now(),
    );

    await const QuranMemorizationReaderLauncher().openTaskReader(
      context: context,
      task: quranTask,
      initialStep: didSelfTest ? 'testing' : 'reading',
    );

    if (!mounted) return;

    setState(() {
      progressRefreshKey++;
      if (!isAlreadyCompleted) {
        didOpenReader = true;
      }
    });
  }

  void _markSelfTestDone() {
    AppHaptics.tap(context);

    if (isAlreadyCompleted) {
      MasterySnackBar.show(
        context,
        message: 'تم تسجيل نتيجة هذه الجلسة من قبل',
      );
      return;
    }

    if (didSelfTest) {
      MasterySnackBar.show(context, message: 'تم تسجيل الاختبار الذاتي بالفعل');
      return;
    }

    if (!didOpenReader) {
      MasterySnackBar.show(context, message: 'افتح القرآن واقرأ المقطع أولًا');
      return;
    }

    setState(() {
      didSelfTest = true;
    });

    MasterySnackBar.show(context, message: 'تمام، قيّم حفظك الآن');
  }

  Future<void> _finishSession() async {
    AppHaptics.tap(context);

    if (isAlreadyCompleted) {
      MasterySnackBar.show(context, message: 'هذه الجلسة مكتملة بالفعل');
      return;
    }

    final rating = selectedRating;

    if (rating == null) {
      MasterySnackBar.show(context, message: 'قيّم حفظك أولًا');
      return;
    }

    if (!didOpenReader) {
      MasterySnackBar.show(context, message: 'افتح القرآن وابدأ الجلسة أولًا');
      return;
    }

    if (!didSelfTest) {
      MasterySnackBar.show(
        context,
        message: 'اختبر نفسك أولًا قبل إنهاء الجلسة',
      );
      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    final now = DateTime.now();
    final actualMinutes = now.difference(startedAt).inMinutes.clamp(1, 180);

    final result = MemorizationSessionResultModel(
      id: 'session_${now.microsecondsSinceEpoch}',
      taskId: widget.task.id,
      taskType: widget.task.type,
      startGlobalAyahIndex: widget.task.startGlobalAyahIndex,
      endGlobalAyahIndex: widget.task.endGlobalAyahIndex,
      ayahsCount:
          widget.task.endGlobalAyahIndex - widget.task.startGlobalAyahIndex + 1,
      rating: rating,
      completedStep: 'completed',
      estimatedMinutes: widget.task.expectedMinutes,
      actualMinutes: actualMinutes,
      needsRescueReview: rating == 'hard' || rating == 'forgot',
      completedAt: now,
    );

    await MemorizationSessionResultStorage.addResult(result);

    await MemorizationPlanStorage.updateTodayTaskForActivePlan(
      widget.task.copyWith(
        status: MemorizationTodayTaskModel.statusCompleted,
        isCompleted: true,
        updatedAt: now,
      ),
    );

    await const MemorizationNextTaskEngine().generateNextTaskAfterSession(
      result: result,
    );

    if (!mounted) return;

    setState(() {
      previousResult = result;
      isSaving = false;
    });

    MasterySnackBar.show(
      context,
      message: rating == 'hard' || rating == 'forgot'
          ? 'تم حفظ التقييم وسيعود هذا المقطع للمراجعة القريبة'
          : 'ما شاء الله، تم حفظ إنجاز الجلسة',
    );

    Navigator.pop(context, true);
  }

  void _selectRating(String rating) {
    AppHaptics.tap(context);

    if (isAlreadyCompleted) {
      MasterySnackBar.show(
        context,
        message: 'لا يمكن تغيير تقييم جلسة مكتملة الآن',
      );
      return;
    }

    if (!didSelfTest) {
      MasterySnackBar.show(context, message: 'اختبر نفسك أولًا ثم قيّم الحفظ');
      return;
    }

    setState(() {
      selectedRating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(category: CustomAppBarCategory(text: 'جلسة الإتقان')),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SessionHeader(
                      title: _sessionTitle,
                      subtitle: _mainInstruction,
                      task: widget.task,
                      isCompleted: isAlreadyCompleted,
                      isRescueSession: isRescueSession,
                    ),
                    SizedBox(height: 12.h),
                    MemorizationTaskProgressCard(
                      key: ValueKey(
                        'taskProgress_${widget.task.id}_$progressRefreshKey',
                      ),
                      task: widget.task,
                    ),
                    if (isRescueSession) ...[
                      SizedBox(height: 12.h),
                      const _RescueStepsCard(),
                    ],
                    SizedBox(height: 14.h),
                    _StepCard(
                      number: '١',
                      title: isRescueSession
                          ? 'افتح القرآن وراجع ببطء'
                          : isSmartTestSession
                          ? 'افتح موضع الاختبار'
                          : 'افتح القرآن واقرأ المقطع',
                      subtitle: isRescueSession
                          ? 'ابدأ بقراءة هادئة للمقطع، وكرر الموضع الذي كان صعبًا عليك.'
                          : isSmartTestSession
                          ? 'افتح المقطع المحدد، ثم اخفِ النص وحاول الاستدعاء من الذاكرة.'
                          : 'سنفتح نفس السورة/المقطع، ونحفظ آخر موضع وصلت له.',
                      isDone: didOpenReader,
                      buttonText: didOpenReader
                          ? 'افتح للمراجعة'
                          : isRescueSession
                          ? 'ابدأ الإنقاذ'
                          : isSmartTestSession
                          ? 'ابدأ الاختبار'
                          : 'ابدأ القراءة',
                      onTap: _openQuranReader,
                    ),
                    SizedBox(height: 10.h),
                    _StepCard(
                      number: '٢',
                      title: isRescueSession
                          ? 'اخفِ النص واختبر التحسن'
                          : isSmartTestSession
                          ? 'استدعِ من الذاكرة'
                          : 'اختبر نفسك بدون نظر',
                      subtitle: isRescueSession
                          ? 'بعد التكرار، اخفِ النص واختبر هل ثبت المقطع أفضل من قبل.'
                          : isSmartTestSession
                          ? 'لا تبحث عن الكمال، الهدف كشف الضعف وتثبيت الحفظ.'
                          : 'اختبار واحد فقط لكل جلسة؛ اخفِ النص ثم قيّم نفسك بصدق.',
                      isDone: didSelfTest,
                      isLocked: isAlreadyCompleted || didSelfTest,
                      buttonText: didSelfTest
                          ? 'تم الاختبار'
                          : isRescueSession
                          ? 'اختبرت التحسن'
                          : isSmartTestSession
                          ? 'اختبرت التثبيت'
                          : 'اختبرت نفسي',
                      onTap: _markSelfTestDone,
                    ),
                    SizedBox(height: 14.h),
                    _RatingCard(
                      selectedRating: selectedRating,
                      isLocked: isAlreadyCompleted,
                      isRescueSession: isRescueSession,
                      isSmartTestSession: isSmartTestSession,
                      onRatingSelected: _selectRating,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.12),
                  ),
                ),
              ),
              child: Opacity(
                opacity: canFinish ? 1 : 0.55,
                child: MasteryPrimaryButton(
                  text: isAlreadyCompleted ? 'تم إنهاء الجلسة' : 'إنهاء الجلسة',
                  icon: isAlreadyCompleted
                      ? Icons.verified_rounded
                      : Icons.check_rounded,
                  onTap: _finishSession,
                  iconAfterText: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
