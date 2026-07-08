import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islamic_app/features/memorization/data/models/memorization_action_type.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_active_plan_model.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_course_certificate.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_calculation_method.dart';
import 'package:islamic_app/features/memorization/data/models/planning/memorization_plan_intensity.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_plan_request.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_option.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_scope_selection.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_session_result_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_test_kind.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_test_preferences.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_today_task_model.dart';
import 'package:islamic_app/features/memorization/data/models/memorization_user_type.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_journey_engine.dart';
import 'package:islamic_app/features/memorization/data/services/planning/memorization_actual_range_summary.dart';
import 'package:islamic_app/features/memorization/data/services/planning/memorization_plan_timeline_resolver.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_preview_builder.dart';
import 'package:islamic_app/features/memorization/data/services/planning/memorization_plan_rescheduler.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_completion_service.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_plan_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_session_result_storage.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_smart_memorization_brain.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_smart_test_planner.dart';
import 'package:islamic_app/features/memorization/data/services/memorization_manual_test_engine.dart';
import 'package:islamic_app/features/memorization/data/services/quran_memorization_range_resolver.dart';
import 'package:islamic_app/features/memorization/data/services/quran_range_label_resolver.dart';
import 'package:islamic_app/features/memorization/presentation/dialogs/memorization_edit_plan_dialog.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_course_certificate_service.dart';
import 'package:islamic_app/features/memorization/test/models/memorization_test_question_model.dart';
import 'package:islamic_app/features/memorization/test/models/standalone_test_settings.dart';
import 'package:islamic_app/features/memorization/results/models/memorization_test_result_model.dart';
import 'package:islamic_app/features/memorization/test/pages/memorization_test_session_page.dart';
import 'package:islamic_app/features/memorization/test/services/memorization_ordering_answer_controller.dart';
import 'package:islamic_app/features/memorization/test/services/memorization_question_history_storage.dart';
import 'package:islamic_app/features/memorization/test/services/memorization_test_question_engine.dart';
import 'package:islamic_app/features/memorization/results/services/memorization_test_result_storage.dart';
import 'package:islamic_app/features/quran/reader/quran_reader_helpers.dart';
import 'package:islamic_app/features/quran/memorization/services/quran_memorization_progress_storage.dart';
import 'package:islamic_app/features/quran/reader/models/quran_ayah_sheet_text.dart';
import 'package:islamic_app/features/quran/reader/quran_page_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('standalone manual test settings', () {
    test(
      'builds an independent task with scope, count, type, and timer choices',
      () async {
        final task = await const MemorizationManualTestEngine()
            .buildManualTestTask(
              const MemorizationManualTestRequest(
                scopeType: StandaloneTestScopeType.surahRange,
                questionMode: StandaloneQuestionMode.completeAyah,
                questionCount: 15,
                difficulty: StandaloneDifficulty.hard,
                timerMode: StandaloneTimerMode.perQuestion,
                surahNumber: 2,
                fromAyah: 1,
                toAyah: 12,
              ),
            );

        expect(task.planId, 'standalone_test');
        expect(task.type, 'standaloneTest');
        expect(task.testTriggerCode, 'standalone');
        expect(task.questionsCount, 15);
        expect(
          task.allowedQuestionTypeCodes,
          contains(MemorizationQuestionType.completeAyah.code),
        );
        expect(task.scopeTitle, contains('سورة'));
      },
    );

    test(
      'timer settings expose no-time, per-question, and full-test modes',
      () {
        final startedAt = DateTime(2026, 6, 22, 10);

        final practice = StandaloneTestSettings(
          id: 'practice',
          scopeType: StandaloneTestScopeType.wholeSurah,
          scopeLabel: 'سورة الفاتحة',
          questionMode: StandaloneQuestionMode.mixed,
          questionCount: 5,
          difficulty: StandaloneDifficulty.easy,
          timerMode: StandaloneTimerMode.none,
          startedAt: startedAt,
        );
        final perQuestion = StandaloneTestSettings(
          id: 'per_question',
          scopeType: StandaloneTestScopeType.wholeSurah,
          scopeLabel: 'سورة الفاتحة',
          questionMode: StandaloneQuestionMode.mixed,
          questionCount: 5,
          difficulty: StandaloneDifficulty.medium,
          timerMode: StandaloneTimerMode.perQuestion,
          secondsPerQuestion: 90,
          startedAt: startedAt,
        );
        final fullTest = StandaloneTestSettings(
          id: 'full_test',
          scopeType: StandaloneTestScopeType.pages,
          scopeLabel: 'الصفحات 1 - 2',
          questionMode: StandaloneQuestionMode.mixed,
          questionCount: 20,
          difficulty: StandaloneDifficulty.hard,
          timerMode: StandaloneTimerMode.fullTest,
          fullTestMinutes: 20,
          startedAt: startedAt,
        );

        expect(practice.isTimed, isFalse);
        expect(perQuestion.isPerQuestionTimed, isTrue);
        expect(perQuestion.perQuestionDuration, const Duration(seconds: 90));
        expect(fullTest.isFullTestTimed, isTrue);
        expect(fullTest.fullTestDuration, const Duration(minutes: 20));
      },
    );
  });

  group('plan dimensions and intensity', () {
    test(
      'whole Quran in 10 days is extreme and uses bounded multi sessions',
      () {
        final preview = const MemorizationPlanPreviewBuilder().build(
          _request(totalPages: 604, totalAyahs: 6236, targetDays: 10),
        );

        expect(preview.targetLearningDays, 10);
        expect(preview.totalPages, 604);
        expect(preview.intensity, MemorizationPlanIntensity.extreme);
        expect(preview.learningSessionsCount, greaterThan(10));
        expect(
          preview.learningSessionsCount,
          lessThanOrEqualTo(
            10 * MemorizationPlanIntensity.extreme.maxLearningSessionsPerDay,
          ),
        );
        expect(preview.plannedTestsCount, 2);
        expect(preview.intensityWarningText, isNotEmpty);
      },
    );

    test('whole Quran in 20 days has compressed checkpoints', () {
      final preview = const MemorizationPlanPreviewBuilder().build(
        _request(totalPages: 604, totalAyahs: 6236, targetDays: 20),
      );

      expect(preview.targetLearningDays, 20);
      expect(preview.learningSessionsCount, greaterThan(20));
      expect(preview.plannedTestsCount, 3);
      expect(preview.plannedTestsCount, lessThan(30));
    });

    test('56 days and 48 pages remain separate dimensions', () {
      final preview = const MemorizationPlanPreviewBuilder().build(
        _request(totalPages: 48, totalAyahs: 520, targetDays: 56),
      );

      expect(preview.targetLearningDays, 56);
      expect(preview.totalPages, 48);
      expect(preview.learningSessionsCount, 48);
      expect(preview.targetLearningDays, isNot(preview.totalPages));
    });

    test('turning tests off keeps automatic test count at zero', () {
      final preview = const MemorizationPlanPreviewBuilder().build(
        _request(
          totalPages: 48,
          totalAyahs: 520,
          targetDays: 56,
        ).copyWith(includeTests: false),
      );

      expect(preview.plannedTestsCount, 0);
      expect(preview.selfTestText, contains('لن تُضاف اختبارات'));
    });
  });

  group('test planning and allocation', () {
    test('short whole-Quran plan does not create 30 checkpoints', () {
      final plan = _plan(totalPages: 604, targetDays: 10);
      final sourceTasks = _sourceTasks(plan: plan, sessions: 38, days: 10);

      final tests = const MemorizationSmartTestPlanner().buildTests(
        plan: plan,
        sourceTasks: sourceTasks,
        results: const [],
        daysAhead: 60,
      );

      expect(tests.length, 2);
      expect(
        tests.map((item) => _dateKey(item.scheduledDate)).toSet().length,
        tests.length,
      );
      expect(tests.where((item) => item.isMandatory).length, 1);
    });

    test('allocator keeps at most one test on a day', () {
      final plan = _plan(totalPages: 604, targetDays: 10);
      final today = DateTime(2026, 6, 21);
      final tasks = <MemorizationJourneyTask>[
        for (int index = 0; index < 4; index++)
          _journeyTask(plan: plan, date: today, type: 'dailyNew', index: index),
        for (int index = 0; index < 5; index++)
          _journeyTask(
            plan: plan,
            date: today,
            type: 'selfTest',
            index: 100 + index,
            ayahsCount: 10 + index,
          ),
      ];

      final allocated = const MemorizationTestDayAllocator().allocate(
        tasks: tasks,
        intensity: MemorizationPlanIntensity.extreme,
        weeklyRestDays: 0,
      );
      final testsPerDay = <String, int>{};
      for (final item in allocated.where(
        (item) => item.task.type == 'selfTest',
      )) {
        final key = _dateKey(item.date);
        testsPerDay[key] = (testsPerDay[key] ?? 0) + 1;
      }

      expect(testsPerDay.values.every((count) => count <= 1), isTrue);
      expect(allocated.length, lessThan(tasks.length));
    });

    test('10-day journey respects session and test caps', () async {
      SharedPreferences.setMockInitialValues({});
      final plan = _plan(totalPages: 604, targetDays: 10);
      final journey = await const MemorizationPlanJourneyEngine()
          .buildJourneyTasks(plan: plan, activeTask: null, daysAhead: 60);

      final learningPerDay = <String, int>{};
      final testsPerDay = <String, int>{};
      for (final item in journey) {
        final key = _dateKey(item.date);
        if (item.task.type == 'selfTest') {
          testsPerDay[key] = (testsPerDay[key] ?? 0) + 1;
        } else if (item.task.type == 'dailyNew') {
          learningPerDay[key] = (learningPerDay[key] ?? 0) + 1;
        }
      }

      expect(learningPerDay.values.every((count) => count == 1), isTrue);
      expect(testsPerDay.values.every((count) => count <= 1), isTrue);
      expect(testsPerDay.values.fold<int>(0, (sum, value) => sum + value), 2);
      final testDates = journey
          .where((item) => item.task.type == 'selfTest')
          .map((item) => _dateKey(item.date))
          .toSet();
      expect(
        journey
            .where((item) => item.task.type == 'dailyNew')
            .every((item) => !testDates.contains(_dateKey(item.date))),
        isTrue,
      );
    });

    test('56-day plan creates weekly, monthly, and final tests', () {
      final plan = _plan(totalPages: 48, targetDays: 56);
      final tests = const MemorizationSmartTestPlanner().buildTests(
        plan: plan,
        sourceTasks: _sourceTasks(plan: plan, sessions: 56, days: 56),
        results: const [],
        daysAhead: 100,
      );

      expect(
        tests.any(
          (item) => item.trigger == MemorizationTestTrigger.weeklyCheckpoint,
        ),
        isTrue,
      );
      expect(
        tests.any(
          (item) => item.trigger == MemorizationTestTrigger.monthlyCheckpoint,
        ),
        isTrue,
      );
      expect(
        tests.any((item) => item.trigger == MemorizationTestTrigger.endOfCycle),
        isTrue,
      );
    });

    test('10-day plan has no literal monthly checkpoint', () {
      final plan = _plan(totalPages: 604, targetDays: 10);
      final tests = const MemorizationSmartTestPlanner().buildTests(
        plan: plan,
        sourceTasks: _sourceTasks(plan: plan, sessions: 40, days: 10),
        results: const [],
        daysAhead: 40,
      );

      expect(
        tests.any(
          (item) => item.trigger == MemorizationTestTrigger.monthlyCheckpoint,
        ),
        isFalse,
      );
    });

    test('disabled automatic tests produce no scheduled tests', () {
      final plan = _plan(
        totalPages: 48,
        targetDays: 56,
      ).copyWith(plannedTestsCount: 0);
      final tests = const MemorizationSmartTestPlanner().buildTests(
        plan: plan,
        sourceTasks: _sourceTasks(plan: plan, sessions: 48, days: 56),
        results: const [],
        daysAhead: 100,
      );

      expect(tests, isEmpty);
    });

    test(
      'internal intensive sessions are one visible daily learning task',
      () async {
        SharedPreferences.setMockInitialValues({});
        final plan = _plan(totalPages: 604, targetDays: 10);
        expect(plan.learningSessionsCount, greaterThan(10));

        final journey = await const MemorizationPlanJourneyEngine()
            .buildJourneyTasks(plan: plan, activeTask: null, daysAhead: 60);
        final visibleLearning = journey
            .where((item) => item.task.type == 'dailyNew')
            .toList();
        final visibleByDay = <String, List<MemorizationJourneyTask>>{};
        for (final item in visibleLearning) {
          visibleByDay.putIfAbsent(_dateKey(item.date), () => []).add(item);
        }

        expect(visibleByDay.values.every((items) => items.length == 1), isTrue);
        expect(
          visibleLearning.every((item) => item.task.title == 'حفظ اليوم'),
          isTrue,
        );
      },
    );

    test('completing merged daily range advances all covered chunks', () async {
      SharedPreferences.setMockInitialValues({});
      final plan = _plan(totalPages: 604, targetDays: 10);
      final engine = const MemorizationPlanJourneyEngine();
      final firstJourney = await engine.buildJourneyTasks(
        plan: plan,
        activeTask: null,
        daysAhead: 60,
      );
      final firstVisible = firstJourney.firstWhere(
        (item) => item.task.type == 'dailyNew',
      );

      await MemorizationSessionResultStorage.addResult(
        MemorizationSessionResultModel(
          id: 'merged_day_done',
          taskId: firstVisible.task.id,
          taskType: 'dailyNew',
          startGlobalAyahIndex: firstVisible.task.startGlobalAyahIndex,
          endGlobalAyahIndex: firstVisible.task.endGlobalAyahIndex,
          ayahsCount: firstVisible.task.ayahsCount,
          rating: 'good',
          completedStep: 'completed',
          estimatedMinutes: firstVisible.task.expectedMinutes,
          actualMinutes: firstVisible.task.expectedMinutes,
          needsRescueReview: false,
          completedAt: DateTime.now(),
        ),
      );

      final nextJourney = await engine.buildJourneyTasks(
        plan: plan,
        activeTask: null,
        daysAhead: 60,
      );
      final nextVisible = nextJourney.firstWhere(
        (item) => item.task.type == 'dailyNew',
      );
      expect(
        nextVisible.task.startGlobalAyahIndex,
        greaterThan(firstVisible.task.endGlobalAyahIndex),
      );
      expect(_dateKey(nextVisible.date), isNot(_dateKey(DateTime.now())));
    });

    test(
      'missed days redistribute instead of stacking all remaining work',
      () async {
        SharedPreferences.setMockInitialValues({});
        final oldPlan = _plan(totalPages: 604, targetDays: 10).copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        );
        final journey = await const MemorizationPlanJourneyEngine()
            .buildJourneyTasks(plan: oldPlan, activeTask: null, daysAhead: 60);

        final learningPerDay = <String, int>{};
        for (final item in journey.where(
          (item) => item.task.type == 'dailyNew',
        )) {
          final key = _dateKey(item.date);
          learningPerDay[key] = (learningPerDay[key] ?? 0) + 1;
        }

        expect(learningPerDay.length, greaterThan(1));
        expect(
          learningPerDay.values.every(
            (count) =>
                count <=
                MemorizationPlanIntensity.extreme.maxLearningSessionsPerDay,
          ),
          isTrue,
        );
      },
    );
  });

  group('mixed seeded question engine', () {
    test('questions are deterministic, mixed, and span the range', () {
      final task = MemorizationTodayTaskModel(
        id: 'task_test',
        planId: 'plan_test',
        type: 'selfTest',
        title: 'اختبار',
        subtitle: '',
        scopeTitle: 'نطاق',
        startGlobalAyahIndex: 0,
        endGlobalAyahIndex: 89,
        expectedMinutes: 10,
        isCompleted: false,
        scheduledDate: DateTime(2026, 6, 21),
        createdAt: DateTime(2026, 6, 21),
        updatedAt: DateTime(2026, 6, 21),
      );
      String resolver(int index) {
        return 'بداية$index كلمة أوسط$index موضع$index نهاية$index ختام$index';
      }

      final engine = const MemorizationTestQuestionEngine();
      final first = engine.buildQuestions(
        task: task,
        ayahTextResolver: resolver,
        maxQuestions: 10,
        attemptNumber: 2,
      );
      final second = engine.buildQuestions(
        task: task,
        ayahTextResolver: resolver,
        maxQuestions: 10,
        attemptNumber: 2,
      );

      expect(first.map((item) => item.id), second.map((item) => item.id));
      expect(first.map((item) => item.type).toSet().length, greaterThan(4));
      expect(first.every((item) => item.type.name == 'orderAyahs'), isFalse);
      final starts = first.map((item) => item.startGlobalAyahIndex).toList();
      expect(starts.reduce((a, b) => a < b ? a : b), lessThan(30));
      expect(starts.reduce((a, b) => a > b ? a : b), greaterThan(59));
    });

    test('question preference controls count and allowed types', () {
      final task = _testTask(
        questionsCount: 15,
        allowedQuestionTypeCodes: const [
          MemorizationTestQuestionCodes.chooseWord,
          MemorizationTestQuestionCodes.chooseAyah,
          MemorizationTestQuestionCodes.nextAyah,
        ],
      );
      final questions = const MemorizationTestQuestionEngine().buildQuestions(
        task: task,
        ayahTextResolver: _testAyahText,
        maxQuestions: task.questionsCount,
      );

      expect(questions, hasLength(15));
      expect(
        questions.every(
          (item) => task.allowedQuestionTypeCodes.contains(item.type.code),
        ),
        isTrue,
      );
    });

    test('fingerprints are unique and recent questions observe cooldown', () {
      final task = _testTask(questionsCount: 10);
      final engine = const MemorizationTestQuestionEngine();
      final first = engine.buildQuestions(
        task: task,
        ayahTextResolver: _testAyahText,
        maxQuestions: 10,
        attemptNumber: 1,
      );
      final second = engine.buildQuestions(
        task: task,
        ayahTextResolver: _testAyahText,
        maxQuestions: 10,
        attemptNumber: 2,
        recentQuestionFingerprints: first
            .map((item) => item.questionFingerprint)
            .toSet(),
      );

      expect(
        first.map((item) => item.questionFingerprint).toSet(),
        hasLength(first.length),
      );
      expect(
        second
            .map((item) => item.questionFingerprint)
            .toSet()
            .intersection(
              first.map((item) => item.questionFingerprint).toSet(),
            ),
        isEmpty,
      );
    });

    test(
      'question history returns fingerprints from recent attempts',
      () async {
        SharedPreferences.setMockInitialValues({});
        final task = _testTask(questionsCount: 5);
        final questions = const MemorizationTestQuestionEngine().buildQuestions(
          task: task,
          ayahTextResolver: _testAyahText,
          maxQuestions: 5,
        );
        const storage = MemorizationQuestionHistoryStorage();
        await storage.saveAttempt(
          planId: task.planId,
          taskId: task.id,
          attemptNumber: 1,
          questions: questions,
        );

        final recent = await storage.getRecentFingerprints(planId: task.planId);
        expect(
          recent,
          containsAll(questions.map((item) => item.questionFingerprint)),
        );
      },
    );

    test('hidden mushaf preference produces hidden reader questions', () {
      final task = _testTask(
        questionsCount: 5,
        testStyleCode: MemorizationTestStyle.hiddenMushaf.code,
        allowedQuestionTypeCodes: const [
          MemorizationTestQuestionCodes.hiddenMushafRecitation,
        ],
      );
      final questions = const MemorizationTestQuestionEngine().buildQuestions(
        task: task,
        ayahTextResolver: _testAyahText,
        maxQuestions: 5,
      );

      expect(questions, hasLength(5));
      expect(
        questions.every(
          (item) =>
              item.type == MemorizationQuestionType.hiddenMushafRecitation,
        ),
        isTrue,
      );
    });

    test('order ayahs always uses a contiguous block from one surah', () {
      final task = _testTask(
        questionsCount: 3,
        allowedQuestionTypeCodes: const [
          MemorizationTestQuestionCodes.orderAyahs,
        ],
      ).copyWith(startGlobalAyahIndex: 0, endGlobalAyahIndex: 40);
      final questions = const MemorizationTestQuestionEngine().buildQuestions(
        task: task,
        ayahTextResolver: _testAyahText,
        maxQuestions: 3,
      );

      expect(questions, isNotEmpty);
      for (final question in questions) {
        final ordered = List<MemorizationQuestionOption>.from(
          question.options,
        )..sort((a, b) => (a.correctOrder ?? 0).compareTo(b.correctOrder ?? 0));
        final indexes = ordered
            .map((option) => int.parse(option.id.split('_').last))
            .toList(growable: false);
        final surahs = indexes
            .map(
              (index) => QuranReaderHelpers.getPositionFromGlobalIndex(
                index,
              ).suraIndex,
            )
            .toSet();
        expect(surahs, hasLength(1));
        for (int index = 1; index < indexes.length; index++) {
          expect(indexes[index], indexes[index - 1] + 1);
        }
      }
    });

    test(
      'order ayahs falls back when a cross-surah range has no valid block',
      () {
        final task = _testTask(
          questionsCount: 3,
          allowedQuestionTypeCodes: const [
            MemorizationTestQuestionCodes.orderAyahs,
          ],
        ).copyWith(startGlobalAyahIndex: 5, endGlobalAyahIndex: 8);
        final questions = const MemorizationTestQuestionEngine().buildQuestions(
          task: task,
          ayahTextResolver: _testAyahText,
          maxQuestions: 3,
        );

        expect(questions, isEmpty);
      },
    );

    test('ayah beginning and ending questions never leak the answer', () {
      final task = _testTask(
        questionsCount: 12,
        allowedQuestionTypeCodes: const ['ayahStarts', 'ayahEndings'],
      );
      final questions = const MemorizationTestQuestionEngine().buildQuestions(
        task: task,
        ayahTextResolver: (index) =>
            'أول$index ثاني$index ثالث$index رابع$index خامس$index سادس$index سابع$index ثامن$index تاسع$index عاشر$index',
        maxQuestions: 12,
      );

      expect(questions, isNotEmpty);
      for (final question in questions) {
        expect(question.prompt.contains(question.correctAnswerText), isFalse);
        expect(question.hint.contains(question.correctAnswerText), isFalse);
        expect(
          question.options
              .where((option) => option.text == question.correctAnswerText)
              .length,
          1,
        );
      }
    });

    test('plan test prompts do not ask to recite a numbered ayah', () {
      final questions = const MemorizationTestQuestionEngine().buildQuestions(
        task: _testTask(questionsCount: 20),
        ayahTextResolver: _testAyahText,
        maxQuestions: 20,
      );
      expect(
        questions.any(
          (question) =>
              question.prompt.contains('سمّع الآية رقم') ||
              question.prompt.contains('اكتب آية رقم'),
        ),
        isFalse,
      );
    });

    test(
      'complete questions show suffix options and keep full text for feedback',
      () {
        final task = _testTask(
          questionsCount: 8,
          allowedQuestionTypeCodes: const [
            MemorizationTestQuestionCodes.completeAyah,
            MemorizationTestQuestionCodes.chooseAyahCompletion,
          ],
        );
        String resolver(int index) {
          return 'بداية $index أول المقطع ثم تأتي تكملة $index الصحيحة في النهاية';
        }

        final questions = const MemorizationTestQuestionEngine().buildQuestions(
          task: task,
          ayahTextResolver: resolver,
          maxQuestions: 8,
        );

        expect(questions, isNotEmpty);
        for (final question in questions) {
          expect(question.promptAyahText, isNotEmpty);
          expect(
            question.fullAyahText,
            resolver(question.startGlobalAyahIndex),
          );
          expect(
            question.options.any(
              (option) =>
                  option.text.startsWith(question.promptAyahText) ||
                  option.text.contains(question.promptAyahText),
            ),
            isFalse,
          );
          expect(question.fullAyahText == question.correctAnswerText, isFalse);
        }
      },
    );

    test(
      'question feedback has source labels without numbered prompts',
      () async {
        await QuranPageMapper.load();
        final questions = const MemorizationTestQuestionEngine().buildQuestions(
          task: _testTask(
            questionsCount: 10,
            allowedQuestionTypeCodes: const [
              MemorizationTestQuestionCodes.nextAyah,
              MemorizationTestQuestionCodes.previousAyah,
            ],
          ),
          ayahTextResolver: _testAyahText,
          maxQuestions: 10,
        );

        expect(questions, isNotEmpty);
        for (final question in questions) {
          expect(question.sourceLabel, contains('سورة'));
          expect(question.pageLabel, isNotEmpty);
          expect(question.prompt, isNot(matches(RegExp(r'\(\d+\)'))));
          expect(question.prompt, isNot(matches(RegExp(r'آية\s+\d+'))));
        }
      },
    );

    test('feedback keeps the exact bundled Hafs Smart ayah text', () async {
      final texts = <int, String>{};
      for (int index = 0; index < 40; index++) {
        final position = QuranReaderHelpers.getPositionFromGlobalIndex(index);
        final text = await QuranAyahSheetTextRepository.instance.getAyahText(
          surah: position.suraIndex + 1,
          ayah: position.ayahIndex + 1,
        );
        texts[index] = text?.hafsText ?? '';
      }

      final questions = const MemorizationTestQuestionEngine().buildQuestions(
        task: _testTask(
          questionsCount: 8,
          allowedQuestionTypeCodes: const [
            MemorizationTestQuestionCodes.completeAyah,
            MemorizationTestQuestionCodes.chooseAyahCompletion,
          ],
        ).copyWith(startGlobalAyahIndex: 0, endGlobalAyahIndex: 39),
        ayahTextResolver: (index) => texts[index] ?? '',
        maxQuestions: 8,
      );

      expect(questions, isNotEmpty);
      for (final question in questions) {
        expect(question.fullAyahText, texts[question.startGlobalAyahIndex]);
      }
    });
  });

  group('timeline, visible ranges, results, and certificate', () {
    test('page range 577 to 604 ends at An-Nas ayah 6', () async {
      final range = await const QuranRangeLabelResolver().resolvePages(
        startPage: 577,
        endPage: 604,
      );

      expect(range.startSurahName, 'المدثر');
      expect(range.startAyahNumber, 48);
      expect(range.endSurahName, 'الناس');
      expect(range.endAyahNumber, 6);
      expect(range.pagesLabel, 'الصفحات: 577 - 604');
      expect(range.displayLabel, contains('إلى سورة الناس آية 6'));
      expect(range.displayLabel, isNot(contains('الغاشية')));
    });

    test('any page range ending at 604 resolves to An-Nas ayah 6', () async {
      final range = await const QuranRangeLabelResolver().resolvePages(
        startPage: 600,
        endPage: 604,
      );

      expect(range.endSurahNumber, 114);
      expect(range.endSurahName, 'الناس');
      expect(range.endAyahNumber, 6);
    });

    test('actual ayah count deduplicates overlapping internal chunks', () {
      final summary = const MemorizationActualRangeSummaryResolver()
          .calculateActualAyahCount(const [
            MemorizationGlobalRange(start: 0, end: 9),
            MemorizationGlobalRange(start: 5, end: 14),
          ]);
      expect(summary.actualAyahCount, 15);
      expect(summary.pageRangeLabel, isNotEmpty);
    });

    test(
      'memorization page progress stores first and last required ayah',
      () async {
        SharedPreferences.setMockInitialValues({});
        await QuranMemorizationProgressStorage.saveProgress(
          taskId: 'page_progress_task',
          suraIndex: 0,
          ayahIndex: 6,
          globalAyahIndex: 6,
          mushafPageNumber: 1,
          pageStartGlobalAyahIndex: 0,
          pageEndGlobalAyahIndex: 6,
          viewMode: 'qpc_connected',
        );

        final progress = await QuranMemorizationProgressStorage.getProgress(
          'page_progress_task',
        );
        expect(progress, isNotNull);
        expect(progress!.pageStartGlobalAyahIndex, 0);
        expect(progress.pageEndGlobalAyahIndex, 6);
        expect(progress.globalAyahIndex, progress.pageEndGlobalAyahIndex);
      },
    );

    test('timeline uses the last real schedule day as source of truth', () {
      final plan = _plan(
        totalPages: 20,
        targetDays: 20,
      ).copyWith(createdAt: DateTime(2026, 6, 1), effectiveCalendarDays: 20);
      final journey = [
        _journeyTask(
          plan: plan,
          date: DateTime(2026, 7, 10),
          type: 'dailyReview',
          index: 0,
        ),
      ];
      final summary = const MemorizationPlanTimelineResolver().resolve(
        plan: plan,
        journeyTasks: journey,
        results: const [],
        now: DateTime(2026, 6, 1),
      );

      expect(summary.targetLearningDays, 20);
      expect(summary.effectiveCalendarDays, 40);
      expect(summary.currentCalendarDay, 1);
      expect(summary.remainingCalendarDays, 39);
    });

    test('detailed test results persist with question breakdown', () async {
      SharedPreferences.setMockInitialValues({});
      final completedAt = DateTime(2026, 6, 21, 12);
      const storage = MemorizationTestResultStorage();
      await storage.addResult(
        MemorizationTestResultModel(
          id: 'stored_test_result',
          planId: 'stored_plan',
          planVersion: 2,
          taskId: 'stored_task',
          testType: 'weeklyCheckpoint',
          scheduledDate: DateTime(2026, 6, 21),
          completedAt: completedAt,
          startGlobalAyahIndex: 0,
          endGlobalAyahIndex: 9,
          questionCount: 1,
          correctCount: 1,
          scorePercent: 100,
          durationSeconds: 25,
          difficulty: 'medium',
          questionTypeBreakdown: const {'chooseWord': 1},
          weakSpots: const [],
          selfEvaluation: 'excellent',
          attemptNumber: 1,
          questionResults: const [
            MemorizationQuestionResultModel(
              questionId: 'q1',
              questionType: 'chooseWord',
              startGlobalAyahIndex: 0,
              endGlobalAyahIndex: 0,
              isCorrect: true,
              selectedAnswer: 'صحيح',
              correctAnswer: 'صحيح',
              timeSpentSeconds: 25,
              mistakeType: '',
            ),
          ],
        ),
      );

      final stored = await storage.getResults(planId: 'stored_plan');
      expect(stored, hasLength(1));
      expect(stored.single.questionResults, hasLength(1));
      expect(stored.single.questionTypeBreakdown['chooseWord'], 1);
    });

    test('symbolic certificate appears only after full memorization', () async {
      SharedPreferences.setMockInitialValues({'user_name': 'أحمد'});
      final plan = _plan(totalPages: 1, targetDays: 2);
      final result = MemorizationSessionResultModel(
        id: 'complete_scope',
        taskId: 'daily',
        taskType: 'dailyNew',
        startGlobalAyahIndex: 0,
        endGlobalAyahIndex: 9,
        ayahsCount: 10,
        rating: 'easy',
        completedStep: 'completed',
        estimatedMinutes: 10,
        actualMinutes: 10,
        needsRescueReview: false,
        completedAt: DateTime.now(),
      );

      final certificate = await const MemorizationCourseCertificateService()
          .buildForPlan(plan: plan, results: [result]);
      final incomplete = await const MemorizationCourseCertificateService()
          .buildForPlan(
            plan: plan,
            results: [
              MemorizationSessionResultModel(
                id: 'incomplete_scope',
                taskId: 'daily_partial',
                taskType: 'dailyNew',
                startGlobalAyahIndex: 0,
                endGlobalAyahIndex: 4,
                ayahsCount: 5,
                rating: 'easy',
                completedStep: 'completed',
                estimatedMinutes: 5,
                actualMinutes: 5,
                needsRescueReview: false,
                completedAt: DateTime.now(),
              ),
            ],
          );

      expect(certificate, isNotNull);
      expect(certificate!.memorizationPercent, 100);
      expect(certificate.userName, 'أحمد');
      expect(
        MemorizationCourseCertificate.disclaimer,
        contains('ليست اعتمادًا رسميًا'),
      );
      expect(incomplete, isNull);
    });

    test(
      'completed plan status is persisted and listed after restart',
      () async {
        final completedAt = DateTime(2026, 6, 21, 12);
        final plan = _plan(totalPages: 1, targetDays: 2).copyWith(
          id: 'completed_plan',
          createdAt: completedAt.subtract(const Duration(days: 2)),
          updatedAt: completedAt.subtract(const Duration(days: 1)),
        );
        final result = MemorizationSessionResultModel(
          id: 'complete_scope_for_status',
          taskId: 'daily',
          taskType: 'dailyNew',
          startGlobalAyahIndex: 0,
          endGlobalAyahIndex: 9,
          ayahsCount: 10,
          rating: 'easy',
          completedStep: 'completed',
          estimatedMinutes: 10,
          actualMinutes: 10,
          needsRescueReview: false,
          completedAt: completedAt,
        );

        SharedPreferences.setMockInitialValues({
          'my_lessons_memorization_plans': jsonEncode([plan.toMap()]),
          'my_lessons_active_memorization_plan_id': plan.id,
        });

        final snapshot = const MemorizationPlanCompletionService().evaluate(
          plan: plan,
          results: [result],
        );
        final stored = await MemorizationPlanStorage.markPlanCompleted(
          planId: plan.id,
          completedAt: completedAt,
          finalCourseScore: 96,
        );
        final active = await MemorizationPlanStorage.getActivePlan();
        final completed = await MemorizationPlanStorage.getCompletedPlans();

        expect(snapshot.isCompleted, isTrue);
        expect(snapshot.completionPercent, 100);
        expect(stored!.isCompleted, isTrue);
        expect(active!.isCompleted, isTrue);
        expect(completed, hasLength(1));
        expect(completed.single.completedAt, completedAt);
        expect(completed.single.finalCourseScore, 96);
      },
    );

    test('starting a new active plan keeps old completed plans', () async {
      final oldCompletedAt = DateTime(2026, 6, 20);
      final oldPlan = _plan(totalPages: 1, targetDays: 2).copyWith(
        id: 'old_completed_plan',
        isActive: false,
        planStatus: MemorizationActivePlanModel.statusCompleted,
        completedAt: oldCompletedAt,
        finalCourseScore: 91,
      );
      final newPlan = _plan(totalPages: 2, targetDays: 4).copyWith(
        id: 'new_active_plan',
        isActive: true,
        planStatus: MemorizationActivePlanModel.statusActive,
      );

      SharedPreferences.setMockInitialValues({
        'my_lessons_memorization_plans': jsonEncode([
          oldPlan.toMap(),
          newPlan.toMap(),
        ]),
        'my_lessons_active_memorization_plan_id': newPlan.id,
      });

      final active = await MemorizationPlanStorage.getActivePlan();
      final completed = await MemorizationPlanStorage.getCompletedPlans();
      final archived = await MemorizationPlanStorage.getArchivedPlans();

      expect(active!.id, newPlan.id);
      expect(completed.map((item) => item.id), contains(oldPlan.id));
      expect(archived.map((item) => item.id), isNot(contains(oldPlan.id)));
    });

    test('certificate score is safe when plan tests are disabled', () async {
      SharedPreferences.setMockInitialValues({'user_name': 'أحمد'});
      final completedAt = DateTime(2026, 6, 21);
      final plan = _plan(totalPages: 1, targetDays: 2).copyWith(
        plannedTestsCount: 0,
        createdAt: completedAt.subtract(const Duration(days: 2)),
      );
      final result = MemorizationSessionResultModel(
        id: 'complete_without_tests',
        taskId: 'daily',
        taskType: 'dailyNew',
        startGlobalAyahIndex: 0,
        endGlobalAyahIndex: 9,
        ayahsCount: 10,
        rating: 'easy',
        completedStep: 'completed',
        estimatedMinutes: 10,
        actualMinutes: 10,
        needsRescueReview: false,
        completedAt: completedAt,
      );

      final certificate = await const MemorizationCourseCertificateService()
          .buildForPlan(plan: plan, results: [result]);

      expect(certificate, isNotNull);
      expect(certificate!.testsEnabled, isFalse);
      expect(certificate.testsAveragePercent, 0);
      expect(certificate.finalScore, greaterThanOrEqualTo(80));
    });
  });

  group('ordering answer controller', () {
    const controller = MemorizationOrderingAnswerController();

    test('tap add/remove and reset preserve unique items', () {
      final added = controller.add(const ['a'], 'b');
      expect(added, ['a', 'b']);
      expect(controller.add(added, 'b'), ['a', 'b']);
      expect(controller.remove(added, 'a'), ['b']);
      expect(controller.reset(), isEmpty);
    });

    test('reorder changes selected order without changing the items', () {
      final reordered = controller.reorder(
        const ['a', 'b', 'c'],
        oldIndex: 0,
        newIndex: 3,
      );
      expect(reordered, ['b', 'c', 'a']);
      expect(reordered.toSet(), {'a', 'b', 'c'});
    });
  });

  group('smart memorization brain', () {
    test('weak results return quickly to spaced review', () {
      final plan = _plan(totalPages: 48, targetDays: 56);
      final completedAt = DateTime(2026, 6, 20);
      final state = const MemorizationSmartMemorizationBrain()
          .buildStates(
            plan: plan.copyWith(
              createdAt: completedAt.subtract(const Duration(days: 1)),
            ),
            results: [
              MemorizationSessionResultModel(
                id: 'weak_result',
                taskId: 'task',
                taskType: 'selfTest',
                startGlobalAyahIndex: 10,
                endGlobalAyahIndex: 20,
                ayahsCount: 11,
                rating: 'forgot',
                completedStep: 'testing',
                estimatedMinutes: 10,
                actualMinutes: 12,
                needsRescueReview: true,
                completedAt: completedAt,
              ),
            ],
          )
          .single;

      expect(state.isWeakSpot, isTrue);
      expect(state.nextReviewDueDate, DateTime(2026, 6, 21));
    });
  });

  group('reschedule preserves completed history', () {
    test(
      '56-day plan can reschedule remaining work without deleting results',
      () async {
        final plan = _plan(totalPages: 48, targetDays: 56);
        final completed = MemorizationSessionResultModel(
          id: 'done_1',
          taskId: 'old_task',
          taskType: 'dailyNew',
          startGlobalAyahIndex: 0,
          endGlobalAyahIndex: 9,
          ayahsCount: 10,
          rating: 'good',
          completedStep: 'completed',
          estimatedMinutes: 10,
          actualMinutes: 10,
          needsRescueReview: false,
          completedAt: DateTime.now(),
        );
        SharedPreferences.setMockInitialValues({
          'my_lessons_memorization_plans': jsonEncode([plan.toMap()]),
          'my_lessons_active_memorization_plan_id': plan.id,
        });
        await MemorizationSessionResultStorage.addResult(completed);

        final updated = await const MemorizationPlanRescheduler()
            .rescheduleActivePlan(
              const MemorizationPlanRescheduleRequest(
                remainingLearningDays: 40,
                weeklyRestDays: 1,
                testPreferences: MemorizationTestPreferences(
                  style: MemorizationTestStyle.smartMixed,
                  questionsPerTest: 15,
                  difficulty: MemorizationTestDifficultyPreference.hard,
                ),
              ),
            );
        final storedResults =
            await MemorizationSessionResultStorage.getResults();

        expect(updated, isNotNull);
        expect(updated!.id, plan.id);
        expect(updated.planVersion, plan.planVersion + 1);
        expect(updated.targetLearningDays, 40);
        expect(updated.testPreferences.questionsPerTest, 15);
        expect(
          updated.testPreferences.difficulty,
          MemorizationTestDifficultyPreference.hard,
        );
        expect(storedResults.map((item) => item.id), contains(completed.id));

        final futureJourney = await const MemorizationPlanJourneyEngine()
            .buildJourneyTasks(plan: updated, activeTask: null, daysAhead: 120);
        final learningByDay = <String, int>{};
        for (final item in futureJourney.where(
          (item) => item.task.type == 'dailyNew',
        )) {
          final key = _dateKey(item.date);
          learningByDay[key] = (learningByDay[key] ?? 0) + 1;
        }
        expect(learningByDay.values.every((count) => count == 1), isTrue);
      },
    );
  });

  group('edit plan dialog UI', () {
    testWidgets('controllers survive typing and dialog can close and reopen', (
      tester,
    ) async {
      final plan = _plan(totalPages: 48, targetDays: 56);

      await tester.pumpWidget(_EditPlanDialogHost(plan: plan));
      await tester.tap(find.byKey(const Key('open_edit_plan')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_plan_remaining_days')),
        '40',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('edit_plan_cancel')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('open_edit_plan')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit_plan_remaining_days')),
        '70',
      );
      await tester.tap(find.byKey(const Key('edit_plan_cancel')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_EditPlanDialogHost(plan: plan));
      await tester.tap(find.byKey(const Key('open_edit_plan')));
      await tester.pumpAndSettle();
      expect(find.byType(MemorizationEditPlanDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'long edit choices and buttons allow three lines without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _EditPlanDialogHost(plan: _plan(totalPages: 604, targetDays: 10)),
        );
        await tester.tap(find.byKey(const Key('open_edit_plan')));
        await tester.pumpAndSettle();

        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.backgroundColor, isNot(Colors.black));

        final extremeTile = find.byKey(const Key('edit_intensity_extreme'));
        expect(extremeTile, findsOneWidget);
        final tileTexts = tester.widgetList<Text>(
          find.descendant(of: extremeTile, matching: find.byType(Text)),
        );
        expect(tileTexts, isNotEmpty);
        expect(tileTexts.every((text) => text.maxLines == 3), isTrue);

        final submitText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('edit_plan_submit')),
            matching: find.byType(Text),
          ),
        );
        expect(submitText.maxLines, 3);
        expect(submitText.softWrap, isTrue);
        expect(find.byKey(const Key('edit_tests_1')), findsNothing);
        expect(find.byKey(const Key('edit_test_style_smartMixed')), findsOne);
        expect(find.byKey(const Key('edit_test_questions_10')), findsOne);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('self evaluation buttons do not overflow on narrow screens', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(300, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            home: MemorizationTestSessionPage(
              task: _testTask(
                questionsCount: 1,
                allowedQuestionTypeCodes: const [
                  MemorizationTestQuestionCodes.noTextRecitation,
                ],
              ),
              ayahTextResolver: _testAyahText,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض النص'));
      await tester.pumpAndSettle();

      expect(find.text('محتاج مراجعة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final evaluationText = tester.widget<Text>(find.text('محتاج مراجعة'));
      expect(evaluationText.maxLines, 3);
    });
  });
}

class _EditPlanDialogHost extends StatelessWidget {
  const _EditPlanDialogHost({required this.plan});

  final MemorizationActivePlanModel plan;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                key: const Key('open_edit_plan'),
                onPressed: () {
                  showDialog<MemorizationPlanRescheduleRequest>(
                    context: context,
                    builder: (_) => MemorizationEditPlanDialog(plan: plan),
                  );
                },
                child: const Text('تعديل الخطة'),
              ),
            );
          },
        ),
      ),
    );
  }
}

MemorizationPlanRequest _request({
  required int totalPages,
  required int totalAyahs,
  required int targetDays,
}) {
  return MemorizationPlanRequest(
    userType: MemorizationUserType.strong,
    actionType: MemorizationActionType.newMemorization,
    scope: MemorizationScopeSelection(
      type: totalPages >= 580
          ? MemorizationScopeType.wholeQuran
          : MemorizationScopeType.pages,
      title: totalPages >= 580 ? 'القرآن كاملًا' : 'صفحات محددة',
      totalAyahs: totalAyahs,
      totalPages: totalPages,
      fromPage: totalPages >= 580 ? null : 1,
      toPage: totalPages >= 580 ? null : totalPages,
    ),
    calculationMethod: MemorizationCalculationMethod.finishByDuration,
    targetDays: targetDays,
    plannedTestsCount: 2,
  );
}

MemorizationActivePlanModel _plan({
  required int totalPages,
  required int targetDays,
}) {
  final intensity = const MemorizationPlanIntensityResolver().resolve(
    totalPages: totalPages,
    targetLearningDays: targetDays,
  );
  final now = DateTime.now();
  return MemorizationActivePlanModel.fromMap({
    'id': 'plan_${totalPages}_$targetDays',
    'planName': 'خطة اختبار',
    'actionTypeName': 'newMemorization',
    'scopeTypeName': totalPages >= 580 ? 'wholeQuran' : 'pages',
    'scopeTitle': totalPages >= 580 ? 'القرآن كاملًا' : 'صفحات',
    'totalDays': targetDays,
    'targetLearningDays': targetDays,
    'effectiveCalendarDays': targetDays + 4,
    'totalAyahs': totalPages >= 580 ? 6236 : totalPages * 10,
    'totalPages': totalPages,
    'dailyNewPages': totalPages / targetDays,
    'learningSessionsCount': (totalPages / intensity.maxPagesPerLearningSession)
        .ceil(),
    'intensityModeName': intensity.code,
    'plannedTestsCount': totalPages >= 580 ? 3 : 2,
    'scopeStartGlobalAyahIndex': 0,
    'scopeEndGlobalAyahIndex': totalPages >= 580 ? 6235 : totalPages * 10 - 1,
    'reviewStartGlobalAyahIndex': 0,
    'reviewEndGlobalAyahIndex': totalPages >= 580 ? 6235 : totalPages * 10 - 1,
    'createdAt': now.toIso8601String(),
    'updatedAt': now.toIso8601String(),
    'isActive': true,
  });
}

List<MemorizationTestSourceTask> _sourceTasks({
  required MemorizationActivePlanModel plan,
  required int sessions,
  required int days,
}) {
  final startDate = DateTime(2026, 6, 1);
  return List.generate(sessions, (index) {
    final day = (index * days / sessions).floor();
    final start = (index * plan.totalAyahs / sessions).floor();
    final end = (((index + 1) * plan.totalAyahs / sessions).ceil() - 1)
        .clamp(start, plan.totalAyahs - 1)
        .toInt();
    final date = startDate.add(Duration(days: day));
    return MemorizationTestSourceTask(
      task: MemorizationTodayTaskModel(
        id: 'source_$index',
        planId: plan.id,
        type: 'dailyNew',
        title: 'جلسة',
        subtitle: '',
        scopeTitle: '',
        startGlobalAyahIndex: start,
        endGlobalAyahIndex: end,
        expectedMinutes: 10,
        isCompleted: false,
        scheduledDate: date,
        createdAt: date,
        updatedAt: date,
      ),
      date: date,
      priority: 1,
    );
  });
}

MemorizationJourneyTask _journeyTask({
  required MemorizationActivePlanModel plan,
  required DateTime date,
  required String type,
  required int index,
  int ayahsCount = 10,
}) {
  return MemorizationJourneyTask(
    task: MemorizationTodayTaskModel(
      id: '${type}_$index',
      planId: plan.id,
      type: type,
      title: type == 'selfTest' ? 'اختبار تثبيت' : 'جلسة حفظ',
      subtitle: '',
      scopeTitle: '',
      startGlobalAyahIndex: index,
      endGlobalAyahIndex: index + ayahsCount - 1,
      expectedMinutes: 10,
      isCompleted: false,
      scheduledDate: date,
      createdAt: date,
      updatedAt: date,
    ),
    date: date,
    timeLabel: type == 'selfTest' ? 'اختبار' : 'حفظ',
    priority: type == 'selfTest' ? 3 : 1,
    isProjected: false,
  );
}

MemorizationTodayTaskModel _testTask({
  int questionsCount = 10,
  String testStyleCode = 'smartMixed',
  List<String> allowedQuestionTypeCodes =
      MemorizationTestQuestionCodes.userSelectable,
}) {
  final date = DateTime(2026, 6, 21);
  return MemorizationTodayTaskModel(
    id: 'preference_test_task',
    planId: 'preference_test_plan',
    type: 'selfTest',
    title: 'اختبار',
    subtitle: '',
    scopeTitle: 'نطاق',
    startGlobalAyahIndex: 0,
    endGlobalAyahIndex: 119,
    expectedMinutes: 12,
    testKindCode: 'randomPassage',
    testTriggerCode: 'weeklyCheckpoint',
    testStyleCode: testStyleCode,
    questionsCount: questionsCount,
    allowedQuestionTypeCodes: allowedQuestionTypeCodes,
    attemptNumber: 1,
    planVersion: 3,
    isCompleted: false,
    scheduledDate: date,
    createdAt: date,
    updatedAt: date,
  );
}

String _testAyahText(int index) {
  return 'بداية$index كلمة$index وسط$index موضع$index نهاية$index ختام$index';
}

String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
