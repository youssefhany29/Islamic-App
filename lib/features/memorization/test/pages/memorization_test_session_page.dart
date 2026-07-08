import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_journey_companion_service.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/quran/main_quraan_components/constant.dart';
import 'package:islamic_app/features/quran/memorization/models/quran_memorization_task_model.dart';
import 'package:islamic_app/features/quran/memorization/services/quran_memorization_reader_launcher.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_test_result_model.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_test_result_storage.dart';
import 'package:islamic_app/shared/widgets/app_main_components/custom_app_bar.dart';
import '../models/memorization_test_question_model.dart';
import '../models/standalone_test_settings.dart';
import '../services/memorization_question_history_storage.dart';
import '../services/memorization_ordering_answer_controller.dart';
import '../services/memorization_test_question_engine.dart';

import 'package:islamic_app/core/typography/app_text_styles.dart';
part '../widgets/memorization_test_question_widgets.dart';
part '../widgets/memorization_test_ordering_widgets.dart';
part '../widgets/memorization_test_evaluation_widgets.dart';
part '../widgets/memorization_test_result_widgets.dart';

class MemorizationTestSessionPage extends StatefulWidget {
  const MemorizationTestSessionPage({
    super.key,
    required this.task,
    this.ayahTextResolver,
    this.standaloneSettings,
  });

  final MemorizationTodayTaskModel task;
  final AyahTextResolver? ayahTextResolver;
  final StandaloneTestSettings? standaloneSettings;

  @override
  State<MemorizationTestSessionPage> createState() =>
      _MemorizationTestSessionPageState();
}

class _MemorizationTestSessionPageState
    extends State<MemorizationTestSessionPage> {
  late final DateTime startedAt;

  List<MemorizationTestQuestionModel> questions = [];
  final Map<String, MemorizationQuestionAnswer> answers = {};
  final Map<String, String> selectedOptionIds = {};
  final Map<String, List<String>> orderedOptionIds = {};
  final Map<String, String> selfEvaluationByQuestionId = {};
  final Map<String, DateTime> questionStartedAt = {};
  final Set<String> revealedTextQuestionIds = {};
  static const orderingAnswerController =
      MemorizationOrderingAnswerController();

  int currentIndex = 0;
  bool isLoadingQuestions = true;
  bool isFinishing = false;
  bool didAutoOpenHiddenMushaf = false;
  bool isHandlingTimerTimeout = false;
  late int currentAttemptNumber;
  Timer? timerTicker;
  DateTime? fullTestEndsAt;
  DateTime? currentQuestionEndsAt;
  int timerRemainingSeconds = 0;
  final Set<String> timedOutQuestionIds = {};
  final Set<String> skippedQuestionIds = {};

  bool get isStandaloneTest => widget.standaloneSettings != null;

  @override
  void initState() {
    super.initState();

    startedAt = DateTime.now();
    currentAttemptNumber =
        widget.standaloneSettings?.attemptNumber ?? widget.task.attemptNumber;
    final standalone = widget.standaloneSettings;
    if (standalone != null && standalone.isFullTestTimed) {
      fullTestEndsAt = startedAt.add(standalone.fullTestDuration);
    }
    _loadQuestions();
  }

  @override
  void dispose() {
    timerTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    await QuranPageMapper.load();
    AyahTextResolver? resolver = widget.ayahTextResolver;

    resolver ??= await _buildDefaultAyahTextResolver();
    final recentFingerprints = await const MemorizationQuestionHistoryStorage()
        .getRecentFingerprints(planId: widget.task.planId);

    final builtQuestions = const MemorizationTestQuestionEngine()
        .buildQuestions(
          task: widget.task,
          ayahTextResolver: resolver,
          maxQuestions: widget.task.questionsCount,
          attemptNumber: currentAttemptNumber,
          recentQuestionFingerprints: recentFingerprints,
        );

    if (!mounted) return;

    setState(() {
      questions = builtQuestions;
      isLoadingQuestions = false;
      if (builtQuestions.isNotEmpty) {
        questionStartedAt.putIfAbsent(
          builtQuestions.first.id,
          () => DateTime.now(),
        );
      }
    });

    _startStandaloneTimerIfNeeded();

    if (!didAutoOpenHiddenMushaf &&
        builtQuestions.isNotEmpty &&
        builtQuestions.first.type ==
            MemorizationQuestionType.hiddenMushafRecitation) {
      didAutoOpenHiddenMushaf = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openHiddenMushaf(builtQuestions.first);
      });
    }
  }

  Future<AyahTextResolver?> _buildDefaultAyahTextResolver() async {
    try {
      final data = await readJson();
      final source = data.isNotEmpty ? data.first : null;
      if (source is! List) return null;

      final texts = source
          .map<String>((item) {
            if (item is Map) {
              return (item['aya_text'] ??
                      item['uthmani'] ??
                      item['text_uthmani'] ??
                      item['aya_text_emlaey'] ??
                      item['text_emlaey'] ??
                      item['imlaei'] ??
                      item['text'] ??
                      '')
                  .toString()
                  .trim();
            }

            return item?.toString().trim() ?? '';
          })
          .toList(growable: false);

      return (globalAyahIndex) {
        if (globalAyahIndex < 0 || globalAyahIndex >= texts.length) {
          return 'تعذر تحميل نص الموضع';
        }

        final text = texts[globalAyahIndex].trim();
        return text.isEmpty ? 'تعذر تحميل نص الموضع' : text;
      };
    } catch (_) {
      return null;
    }
  }

  void _startStandaloneTimerIfNeeded() {
    final settings = widget.standaloneSettings;
    if (settings == null || !settings.isTimed || questions.isEmpty) return;

    if (settings.isPerQuestionTimed) {
      _startQuestionTimerForCurrentQuestion();
    }

    timerTicker?.cancel();
    timerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncStandaloneTimer();
    });
    _syncStandaloneTimer();
  }

  void _startQuestionTimerForCurrentQuestion() {
    final settings = widget.standaloneSettings;
    final question = currentQuestion;
    if (settings == null ||
        question == null ||
        !settings.isPerQuestionTimed ||
        _isAnswered(question)) {
      currentQuestionEndsAt = null;
      timerRemainingSeconds = 0;
      return;
    }

    final started = questionStartedAt.putIfAbsent(
      question.id,
      () => DateTime.now(),
    );
    currentQuestionEndsAt = started.add(settings.perQuestionDuration);
  }

  void _syncStandaloneTimer() {
    if (!mounted || isFinishing || isHandlingTimerTimeout) return;
    final settings = widget.standaloneSettings;
    if (settings == null || !settings.isTimed) return;

    final now = DateTime.now();
    final DateTime? activeEnd = settings.isFullTestTimed
        ? fullTestEndsAt
        : currentQuestionEndsAt;

    if (activeEnd == null) return;

    final remaining = activeEnd.difference(now).inSeconds;
    if (mounted) {
      setState(() {
        timerRemainingSeconds = remaining.clamp(0, 24 * 60 * 60).toInt();
      });
    }

    if (remaining > 0) return;

    if (settings.isFullTestTimed) {
      unawaited(_finishTest(timeExpired: true));
    } else {
      unawaited(_handlePerQuestionTimeout());
    }
  }

  Future<void> _handlePerQuestionTimeout() async {
    if (isHandlingTimerTimeout || isFinishing) return;
    final question = currentQuestion;
    if (question == null) return;

    isHandlingTimerTimeout = true;
    if (!_isAnswered(question)) {
      final now = DateTime.now();
      setState(() {
        timedOutQuestionIds.add(question.id);
        skippedQuestionIds.add(question.id);
        answers[question.id] = MemorizationQuestionAnswer(
          questionId: question.id,
          isCorrect: false,
          answeredAt: now,
          timedOut: true,
          skipped: true,
        );
      });
    }

    if (currentIndex >= questions.length - 1) {
      isHandlingTimerTimeout = false;
      await _finishTest(timeExpired: true);
      return;
    }

    if (mounted) {
      setState(() {
        currentIndex++;
        questionStartedAt.putIfAbsent(
          questions[currentIndex].id,
          () => DateTime.now(),
        );
      });
      _startQuestionTimerForCurrentQuestion();
    }

    isHandlingTimerTimeout = false;
  }

  String get _timerLabel {
    final seconds = timerRemainingSeconds.clamp(0, 24 * 60 * 60).toInt();
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  MemorizationTestQuestionModel? get currentQuestion {
    if (questions.isEmpty) return null;
    final safeIndex = currentIndex.clamp(0, questions.length - 1).toInt();
    return questions[safeIndex];
  }

  int get correctAnswersCount {
    return answers.values.where((answer) => answer.isCorrect).length;
  }

  double get score {
    if (questions.isEmpty) return 0;
    return correctAnswersCount / questions.length;
  }

  String get rating {
    if (score >= 0.9) return 'easy';
    if (score >= 0.7) return 'good';
    if (score >= 0.45) return 'hard';
    return 'forgot';
  }

  String get ratingTitle {
    if (score >= 0.9) return 'ممتاز جدًا';
    if (score >= 0.7) return 'جيد جدًا';
    if (score >= 0.45) return 'يحتاج تثبيت';
    return 'يحتاج مراجعة قوية';
  }

  String get ratingMessage {
    if (score >= 0.9) {
      return 'أداؤك قوي جدًا. كمل بنفس الهدوء، والاختبارات القادمة هتظهر في وقتها.';
    }

    if (score >= 0.7) {
      return 'أداؤك جيد، لكن في مواضع بسيطة محتاجة تثبيت قبل ما تثقل على نفسك.';
    }

    if (score >= 0.45) {
      return 'في مواضع محتاجة رحلة تثبيت قصيرة. جهزنا لك خطة هادئة بدل ما نسيبك محتار.';
    }

    return 'الأفضل نبدأ رحلة تثبيت قصيرة قبل أي حفظ جديد، بدون ضغط وبدون تراكم.';
  }

  bool _isAnswered(MemorizationTestQuestionModel question) {
    return answers.containsKey(question.id);
  }

  bool _isCorrect(MemorizationTestQuestionModel question) {
    return answers[question.id]?.isCorrect ?? false;
  }

  void _selectOption({
    required MemorizationTestQuestionModel question,
    required MemorizationQuestionOption option,
  }) {
    if (_isAnswered(question)) return;

    setState(() {
      selectedOptionIds[question.id] = option.id;

      answers[question.id] = MemorizationQuestionAnswer(
        questionId: question.id,
        isCorrect: option.isCorrect,
        answeredAt: DateTime.now(),
      );
    });
  }

  void _selectOrderingOption({
    required MemorizationTestQuestionModel question,
    required MemorizationQuestionOption option,
  }) {
    if (_isAnswered(question)) return;

    final currentOrder = List<String>.from(
      orderedOptionIds[question.id] ?? const <String>[],
    );

    setState(() {
      orderedOptionIds[question.id] = orderingAnswerController.add(
        currentOrder,
        option.id,
      );
    });
  }

  void _clearOrderingAnswer(MemorizationTestQuestionModel question) {
    if (_isAnswered(question)) return;
    setState(() {
      orderedOptionIds.remove(question.id);
    });
  }

  void _removeOrderingOption({
    required MemorizationTestQuestionModel question,
    required MemorizationQuestionOption option,
  }) {
    if (_isAnswered(question)) return;
    final currentOrder = List<String>.from(
      orderedOptionIds[question.id] ?? const <String>[],
    );
    if (!currentOrder.contains(option.id)) return;
    setState(
      () => orderedOptionIds[question.id] = orderingAnswerController.remove(
        currentOrder,
        option.id,
      ),
    );
  }

  void _reorderOrderingOptions({
    required MemorizationTestQuestionModel question,
    required int oldIndex,
    required int newIndex,
  }) {
    if (_isAnswered(question)) return;
    final currentOrder = List<String>.from(
      orderedOptionIds[question.id] ?? const <String>[],
    );
    setState(
      () => orderedOptionIds[question.id] = orderingAnswerController.reorder(
        currentOrder,
        oldIndex: oldIndex,
        newIndex: newIndex,
      ),
    );
  }

  void _submitOrderingAnswer(MemorizationTestQuestionModel question) {
    if (_isAnswered(question)) return;

    final selected = orderedOptionIds[question.id] ?? const <String>[];
    if (selected.length != question.options.length) {
      _showSnackBar('رتّب كل العناصر الأول.');
      return;
    }

    final optionById = <String, MemorizationQuestionOption>{
      for (final option in question.options) option.id: option,
    };

    bool correct = true;
    for (int i = 0; i < selected.length; i++) {
      final option = optionById[selected[i]];
      if (option == null || option.correctOrder != i) {
        correct = false;
        break;
      }
    }

    setState(() {
      answers[question.id] = MemorizationQuestionAnswer(
        questionId: question.id,
        isCorrect: correct,
        answeredAt: DateTime.now(),
      );
    });
  }

  void _revealText(MemorizationTestQuestionModel question) {
    if (_isAnswered(question)) return;

    setState(() {
      revealedTextQuestionIds.add(question.id);
    });
  }

  Future<void> _openHiddenMushaf(MemorizationTestQuestionModel question) async {
    final task = QuranMemorizationTaskModel(
      id: '${widget.task.id}_${question.id}',
      type: 'test',
      startGlobalAyahIndex: question.startGlobalAyahIndex,
      endGlobalAyahIndex: question.endGlobalAyahIndex,
      title: question.title,
      subtitle: question.hint,
      estimatedMinutes: widget.task.expectedMinutes,
      dueDate: widget.task.effectiveScheduledDate,
    );
    await const QuranMemorizationReaderLauncher().openTaskReader(
      context: context,
      task: task,
      initialStep: 'testing',
    );
  }

  void _submitSelfEvaluation({
    required MemorizationTestQuestionModel question,
    required String evaluation,
  }) {
    if (_isAnswered(question)) return;

    setState(() {
      selfEvaluationByQuestionId[question.id] = evaluation;
      answers[question.id] = MemorizationQuestionAnswer(
        questionId: question.id,
        isCorrect: evaluation == 'excellent' || evaluation == 'good',
        answeredAt: DateTime.now(),
      );
    });
  }

  void _previous() {
    if (currentIndex <= 0) return;

    setState(() {
      currentIndex--;
    });
    _startQuestionTimerForCurrentQuestion();
  }

  Future<void> _nextOrFinish() async {
    final question = currentQuestion;
    if (question == null || isFinishing) return;

    if (!_isAnswered(question)) {
      _showSnackBar(
        question.hasOptions
            ? 'اختار إجابة الأول، وبعدها كمل.'
            : 'اضغط عرض النص وقيّم تسميعك الأول.',
      );
      return;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        questionStartedAt.putIfAbsent(
          questions[currentIndex].id,
          () => DateTime.now(),
        );
      });
      _startQuestionTimerForCurrentQuestion();
      return;
    }

    await _finishTest();
  }

  Future<void> _finishTest({bool timeExpired = false}) async {
    if (isFinishing) return;

    setState(() => isFinishing = true);
    timerTicker?.cancel();

    final completedAt = DateTime.now();
    final actualMinutes = completedAt
        .difference(startedAt)
        .inMinutes
        .clamp(1, 999)
        .toInt();

    await const MemorizationTestResultStorage().addResult(
      _buildDetailedTestResult(completedAt),
    );
    await const MemorizationQuestionHistoryStorage().saveAttempt(
      planId: widget.task.planId,
      taskId: widget.task.id,
      attemptNumber: currentAttemptNumber,
      questions: questions,
      completedAt: completedAt,
    );

    MemorizationActivePlanModel? activePlan;
    MemorizationQuickStabilizationPlan? quickPlan;

    if (!isStandaloneTest) {
      final result = MemorizationSessionResultModel(
        id: 'test_result_${completedAt.microsecondsSinceEpoch}',
        taskId: widget.task.id,
        taskType: widget.task.type,
        startGlobalAyahIndex: widget.task.startGlobalAyahIndex,
        endGlobalAyahIndex: widget.task.endGlobalAyahIndex,
        ayahsCount: widget.task.ayahsCount,
        rating: rating,
        completedStep: 'testing',
        estimatedMinutes: widget.task.expectedMinutes,
        actualMinutes: actualMinutes,
        needsRescueReview: score < 0.7,
        completedAt: completedAt,
      );

      await MemorizationSessionResultStorage.addResult(result);

      activePlan = await MemorizationPlanStorage.getActivePlan();
      quickPlan = _buildQuickPlanFromTest(
        activePlan: activePlan,
        result: result,
      );
    }

    if (!mounted) return;

    setState(() => isFinishing = false);

    _showResultBottomSheet(
      activePlan: activePlan,
      quickPlan: quickPlan,
      timeExpired: timeExpired,
    );
  }

  MemorizationTestResultModel _buildDetailedTestResult(DateTime completedAt) {
    final questionResults = questions
        .map((question) {
          final answer = answers[question.id];
          final selectedAnswer = _selectedAnswerText(question);
          final started = questionStartedAt[question.id] ?? startedAt;
          final answeredAt = answer?.answeredAt ?? completedAt;
          return MemorizationQuestionResultModel(
            questionId: question.id,
            questionType: question.type.code,
            startGlobalAyahIndex: question.startGlobalAyahIndex,
            endGlobalAyahIndex: question.endGlobalAyahIndex,
            isCorrect: answer?.isCorrect ?? false,
            selectedAnswer: selectedAnswer,
            correctAnswer: question.correctAnswerText,
            timeSpentSeconds: answeredAt
                .difference(started)
                .inSeconds
                .clamp(0, 3600)
                .toInt(),
            timedOut:
                answer?.timedOut == true ||
                timedOutQuestionIds.contains(question.id),
            skipped:
                answer?.skipped == true ||
                skippedQuestionIds.contains(question.id),
            mistakeType: answer?.isCorrect == true ? '' : question.type.code,
          );
        })
        .toList(growable: false);

    final breakdown = <String, int>{};
    for (final question in questions) {
      breakdown.update(
        question.type.code,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final weakSpots = questionResults
        .where((item) => !item.isCorrect)
        .map(
          (item) => '${item.startGlobalAyahIndex}:${item.endGlobalAyahIndex}',
        )
        .toSet()
        .toList(growable: false);

    return MemorizationTestResultModel(
      id: isStandaloneTest
          ? 'standalone_test_${completedAt.microsecondsSinceEpoch}'
          : 'detailed_test_${completedAt.microsecondsSinceEpoch}',
      planId: widget.task.planId,
      planVersion: widget.task.planVersion,
      taskId: widget.task.id,
      testType: isStandaloneTest
          ? widget.standaloneSettings!.questionModeCode
          : widget.task.testTriggerCode.isNotEmpty
          ? widget.task.testTriggerCode
          : widget.task.testKindCode,
      scope: isStandaloneTest ? widget.standaloneSettings!.scopeLabel : '',
      timerMode: widget.standaloneSettings?.timerModeCode ?? 'none',
      startedAt: startedAt,
      scheduledDate: widget.task.effectiveScheduledDate,
      completedAt: completedAt,
      startGlobalAyahIndex: widget.task.startGlobalAyahIndex,
      endGlobalAyahIndex: widget.task.endGlobalAyahIndex,
      questionCount: questions.length,
      correctCount: correctAnswersCount,
      wrongCount:
          (questions.length - correctAnswersCount - skippedQuestionIds.length)
              .clamp(0, questions.length)
              .toInt(),
      skippedCount: skippedQuestionIds.length,
      timeoutCount: timedOutQuestionIds.length,
      scorePercent: score * 100,
      durationSeconds: completedAt.difference(startedAt).inSeconds,
      totalDurationSeconds: completedAt.difference(startedAt).inSeconds,
      difficulty:
          widget.standaloneSettings?.difficultyCode ??
          widget.task.testDifficultyPreferenceCode,
      questionTypeBreakdown: breakdown,
      weakSpots: weakSpots,
      selfEvaluation: _aggregateSelfEvaluation(),
      attemptNumber: currentAttemptNumber,
      questionResults: questionResults,
    );
  }

  String _selectedAnswerText(MemorizationTestQuestionModel question) {
    if (question.isOrderingQuestion) {
      final selectedIds = orderedOptionIds[question.id] ?? const <String>[];
      final optionById = {
        for (final option in question.options) option.id: option.text,
      };
      return selectedIds
          .map((id) => optionById[id] ?? '')
          .where((text) => text.isNotEmpty)
          .join('\n');
    }

    final selectedId = selectedOptionIds[question.id];
    if (selectedId != null) {
      for (final option in question.options) {
        if (option.id == selectedId) return option.text;
      }
    }

    return selfEvaluationByQuestionId[question.id] ?? '';
  }

  String _aggregateSelfEvaluation() {
    if (selfEvaluationByQuestionId.isEmpty) return '';
    const priority = <String, int>{
      'excellent': 0,
      'good': 1,
      'fewMistakes': 2,
      'needsReview': 3,
    };
    return selfEvaluationByQuestionId.values.reduce((current, next) {
      return (priority[next] ?? 0) > (priority[current] ?? 0) ? next : current;
    });
  }

  MemorizationQuickStabilizationPlan? _buildQuickPlanFromTest({
    required MemorizationActivePlanModel? activePlan,
    required MemorizationSessionResultModel result,
  }) {
    if (activePlan == null) return null;
    if (score >= 0.7) return null;
    if (!widget.task.hasValidRange) return null;

    final ayahsCount = widget.task.ayahsCount.clamp(1, 999999).toInt();

    int days;
    if (score < 0.45) {
      days = 7;
    } else if (ayahsCount > 80) {
      days = 7;
    } else if (ayahsCount > 40) {
      days = 5;
    } else {
      days = 4;
    }

    final estimatedDailyAyahs = (ayahsCount / days).ceil().clamp(1, 40).toInt();

    return MemorizationQuickStabilizationPlan(
      title: 'رحلة تثبيت بعد الاختبار',
      subtitle: widget.task.scopeTitle.trim().isEmpty
          ? 'تثبيت مواضع الاختبار'
          : widget.task.scopeTitle,
      days: days,
      startGlobalAyahIndex: widget.task.startGlobalAyahIndex,
      endGlobalAyahIndex: widget.task.endGlobalAyahIndex,
      estimatedDailyAyahs: estimatedDailyAyahs,
      plannedTestsCount: days >= 7 ? 2 : 1,
      focusPoints: [
        if (score < 0.45)
          'ابدأ بتسميع قصير، واضغط عرض النص عند الحاجة بدون استعجال.'
        else
          'راجع المواضع التي أخطأت فيها قبل دخول اختبار جديد.',
        'ركّز على ترتيب الآيات والانتقال من آية للي بعدها.',
        'خلي الرحلة قصيرة وثابتة بدل تراكم كبير.',
      ],
    );
  }

  Future<void> _activateQuickPlan({
    required MemorizationActivePlanModel activePlan,
    required MemorizationQuickStabilizationPlan quickPlan,
  }) async {
    Navigator.of(context).pop();

    setState(() => isFinishing = true);

    await const MemorizationJourneyCompanionService()
        .activateQuickStabilizationPlan(
          quickPlan: quickPlan,
          sourcePlan: activePlan,
        );

    if (!mounted) return;

    setState(() => isFinishing = false);

    _showSnackBar('تم وضع رحلة التثبيت في التقويم بهدوء 🌿');

    Navigator.of(context).pop(true);
  }

  void _showResultBottomSheet({
    required MemorizationActivePlanModel? activePlan,
    required MemorizationQuickStabilizationPlan? quickPlan,
    required bool timeExpired,
  }) {
    final completedAt = DateTime.now();
    final durationSeconds = completedAt
        .difference(startedAt)
        .inSeconds
        .clamp(0, 24 * 60 * 60)
        .toInt();
    final skippedCount = skippedQuestionIds.length;
    final timeoutCount = timedOutQuestionIds.length;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TestResultSheet(
          totalQuestions: questions.length,
          correctAnswers: correctAnswersCount,
          skippedCount: skippedCount,
          timeoutCount: timeoutCount,
          durationSeconds: durationSeconds,
          score: score,
          ratingTitle: ratingTitle,
          ratingMessage: ratingMessage,
          isStandalone: isStandaloneTest,
          timeExpired: timeExpired,
          timerLabel: widget.standaloneSettings?.timerLabel ?? '',
          questionTypeBreakdown: _questionTypeBreakdown(),
          quickPlan: quickPlan,
          canActivateQuickPlan: activePlan != null && quickPlan != null,
          onActivateQuickPlan: activePlan == null || quickPlan == null
              ? null
              : () => _activateQuickPlan(
                  activePlan: activePlan,
                  quickPlan: quickPlan,
                ),
          onReviewAgain: () {
            Navigator.of(context).pop();

            setState(() {
              currentAttemptNumber++;
              didAutoOpenHiddenMushaf = false;
              isHandlingTimerTimeout = false;
              currentIndex = 0;
              questions = const [];
              answers.clear();
              selectedOptionIds.clear();
              orderedOptionIds.clear();
              selfEvaluationByQuestionId.clear();
              questionStartedAt.clear();
              revealedTextQuestionIds.clear();
              timedOutQuestionIds.clear();
              skippedQuestionIds.clear();
              timerRemainingSeconds = 0;
              currentQuestionEndsAt = null;
              fullTestEndsAt =
                  widget.standaloneSettings?.isFullTestTimed == true
                  ? DateTime.now().add(
                      widget.standaloneSettings!.fullTestDuration,
                    )
                  : null;
              isLoadingQuestions = true;
            });
            _loadQuestions();
          },
          onClose: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(true);
          },
        );
      },
    );
  }

  Map<String, int> _questionTypeBreakdown() {
    final breakdown = <String, int>{};
    for (final question in questions) {
      breakdown.update(
        question.type.title,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return breakdown;
  }

  Future<bool> _confirmExitIfNeeded() async {
    final settings = widget.standaloneSettings;
    if (settings == null ||
        !settings.isTimed ||
        isFinishing ||
        questions.isEmpty) {
      return true;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.colorScheme.secondary,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.r),
            ),
            title: Text(
              'الخروج من الاختبار؟',
              textAlign: TextAlign.right,
              style: AppTextStyles.body(dialogContext).copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.surface,
              ),
            ),
            content: Text(
              'الاختبار عليه وقت. لو خرجت الآن لن يتم حفظ محاولة مكتملة.',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(dialogContext).copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.surface.withOpacity(0.70),
                height: 1.55,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('متابعة الاختبار'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'خروج',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        );
      },
    );

    return shouldExit ?? false;
  }

  Future<void> _handleBackPressed() async {
    final canExit = await _confirmExitIfNeeded();
    if (!mounted || !canExit) return;
    Navigator.of(context).pop();
  }

  void _showSnackBar(String message) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.caption(context).copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.background,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = currentQuestion;

    return WillPopScope(
      onWillPop: _confirmExitIfNeeded,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: CustomAppBar(
          category: CustomAppBarCategory(
            text: isStandaloneTest ? 'اختبرني' : 'اختبار التثبيت',
          ),
          subtitle: isStandaloneTest
              ? widget.standaloneSettings!.questionModeLabel
              : widget.task.scopeTitle,
          onBackPressed: () => unawaited(_handleBackPressed()),
        ),
        body: SafeArea(
          child: isLoadingQuestions
              ? const Center(child: CircularProgressIndicator())
              : question == null
              ? const _EmptyTestState()
              : Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.standaloneSettings?.isTimed == true) ...[
                        _StandaloneTimerBanner(
                          label: _timerLabel,
                          modeLabel: widget.standaloneSettings!.timerLabel,
                          isLastWarning: timerRemainingSeconds <= 30,
                        ),
                        SizedBox(height: 10.h),
                      ],
                      Expanded(
                        child: _QuestionCard(
                          question: question,
                          currentQuestionNumber: currentIndex + 1,
                          totalQuestions: questions.length,
                          quranFontSize: isStandaloneTest ? 24.sp : 16.sp,
                          optionQuranFontSize: isStandaloneTest ? 21.sp : 16.sp,
                          isAnswered: _isAnswered(question),
                          isCorrect: _isCorrect(question),
                          isTextRevealed: revealedTextQuestionIds.contains(
                            question.id,
                          ),
                          selectedOptionId: selectedOptionIds[question.id],
                          orderedOptionIds:
                              orderedOptionIds[question.id] ?? const <String>[],
                          onOptionTap: (option) {
                            _selectOption(question: question, option: option);
                          },
                          onOrderingOptionTap: (option) {
                            _selectOrderingOption(
                              question: question,
                              option: option,
                            );
                          },
                          onRemoveOrderingOption: (option) {
                            _removeOrderingOption(
                              question: question,
                              option: option,
                            );
                          },
                          onReorderOrderingOptions: (oldIndex, newIndex) {
                            _reorderOrderingOptions(
                              question: question,
                              oldIndex: oldIndex,
                              newIndex: newIndex,
                            );
                          },
                          onClearOrdering: () => _clearOrderingAnswer(question),
                          onSubmitOrdering: () =>
                              _submitOrderingAnswer(question),
                          onRevealText: () => _revealText(question),
                          onOpenHiddenMushaf: () => _openHiddenMushaf(question),
                          onSelfEvaluation: (evaluation) {
                            _submitSelfEvaluation(
                              question: question,
                              evaluation: evaluation,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _TestButton(
                              label: currentIndex == questions.length - 1
                                  ? isFinishing
                                        ? 'جاري الحفظ...'
                                        : 'إنهاء الاختبار'
                                  : 'التالي',
                              icon: currentIndex == questions.length - 1
                                  ? Icons.done_all_rounded
                                  : Icons.arrow_back_rounded,
                              iconAfterLabel:
                                  currentIndex != questions.length - 1,
                              onTap: _nextOrFinish,
                              isPrimary: true,
                              isDisabled: isFinishing,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _TestButton(
                              label: 'السابق',
                              icon: Icons.arrow_forward_rounded,
                              onTap: _previous,
                              isPrimary: false,
                              isDisabled: currentIndex == 0 || isFinishing,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
