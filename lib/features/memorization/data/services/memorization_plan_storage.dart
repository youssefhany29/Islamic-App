import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../quran/reader/quran_page_mapper.dart';
import '../../../quran/reader/quran_reader_helpers.dart';
import '../models/memorization_active_plan_model.dart';
import '../models/memorization_action_type.dart';
import '../models/memorization_plan_preview_model.dart';
import '../models/memorization_plan_request.dart';
import '../models/memorization_scope_option.dart';
import '../models/memorization_today_task_model.dart';
import 'memorization_session_result_storage.dart';
import 'quran_memorization_hizb_boundaries.dart';

class MemorizationPlanStorage {
  static const String _plansKey = 'my_lessons_memorization_plans';
  static const String _activePlanIdKey =
      'my_lessons_active_memorization_plan_id';

  static const String _legacyActivePlanKey =
      'my_lessons_active_memorization_plan';
  static const String _legacyTodayTaskKey =
      'my_lessons_today_memorization_task';

  static const String _taskPrefix = 'my_lessons_today_memorization_task_';

  const MemorizationPlanStorage._();

  static Future<void> activatePlan({
    required MemorizationPlanRequest request,
    required MemorizationPlanPreviewModel preview,
    String? planName,
  }) async {
    await QuranPageMapper.load();

    final prefs = await SharedPreferences.getInstance();

    await _migrateOldSinglePlanIfNeeded(prefs);

    final oldPlans = await getPlans();

    final now = DateTime.now();

    final archivedOldPlans = oldPlans.map((plan) {
      if (!plan.isActive) return plan;

      return plan.copyWith(
        isActive: false,
        planStatus: plan.isCompleted
            ? MemorizationActivePlanModel.statusCompleted
            : MemorizationActivePlanModel.statusPaused,
        updatedAt: now,
      );
    }).toList();

    final range = _buildTaskRange(request);
    final reviewRange = request.reviewScope == null
        ? range
        : _buildRangeFromScope(request.reviewScope!);

    final newPlan = MemorizationActivePlanModel.fromRequest(
      request: request,
      preview: preview,
      planName: planName,
      scopeStartGlobalAyahIndex: range.startGlobalAyahIndex,
      scopeEndGlobalAyahIndex: range.endGlobalAyahIndex,
      reviewStartGlobalAyahIndex: reviewRange.startGlobalAyahIndex,
      reviewEndGlobalAyahIndex: reviewRange.endGlobalAyahIndex,
      reviewScopeTitle: request.reviewScope?.rangeText,
    );

    final todayTask = _buildFirstTodayTask(
      request: request,
      plan: newPlan,
      range: range,
    );

    if (!todayTask.hasValidRange) {
      throw Exception(
        'نطاق مهمة اليوم غير صحيح. تأكد من اختيار السورة أو الآيات.',
      );
    }

    final updatedPlans = <MemorizationActivePlanModel>[
      newPlan,
      ...archivedOldPlans.where((plan) => plan.id != newPlan.id),
    ];

    await _savePlans(updatedPlans);
    await prefs.setString(_activePlanIdKey, newPlan.id);

    await _saveTaskForPlan(planId: newPlan.id, task: todayTask);

    await prefs.setString(_legacyActivePlanKey, jsonEncode(newPlan.toMap()));

    await prefs.setString(_legacyTodayTaskKey, jsonEncode(todayTask.toMap()));
  }

  static Future<List<MemorizationActivePlanModel>> getPlans() async {
    final prefs = await SharedPreferences.getInstance();

    await _migrateOldSinglePlanIfNeeded(prefs);

    final raw = prefs.getString(_plansKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final plans = decoded
          .whereType<Map>()
          .map(
            (item) => MemorizationActivePlanModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((plan) => plan.id.trim().isNotEmpty)
          .toList();

      plans.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return plans;
    } catch (_) {
      return [];
    }
  }

  static Future<List<MemorizationActivePlanModel>> getArchivedPlans() async {
    final plans = await getPlans();
    return plans.where((plan) => !plan.isActive && !plan.isCompleted).toList();
  }

  static Future<List<MemorizationActivePlanModel>> getCompletedPlans() async {
    final plans = await getPlans();
    final completed = plans.where((plan) => plan.isCompleted).toList();
    completed.sort((a, b) {
      final aDate = a.completedAt ?? a.updatedAt;
      final bDate = b.completedAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });
    return completed;
  }

  static Future<void> _savePlans(
    List<MemorizationActivePlanModel> plans,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _plansKey,
      jsonEncode(plans.map((plan) => plan.toMap()).toList()),
    );
  }

  static Future<MemorizationActivePlanModel?> getActivePlan() async {
    final plans = await getPlans();

    for (final plan in plans) {
      if (plan.isActive) return plan;
    }

    return null;
  }

  static Future<bool> hasActivePlan() async {
    final activePlan = await getActivePlan();
    return activePlan != null;
  }

  static Future<void> stopActivePlan() async {
    final activePlan = await getActivePlan();
    if (activePlan == null) return;

    final plans = await getPlans();
    final now = DateTime.now();

    final updatedPlans = plans.map((plan) {
      if (plan.id != activePlan.id) return plan;

      return plan.copyWith(
        isActive: false,
        planStatus: plan.isCompleted
            ? MemorizationActivePlanModel.statusCompleted
            : MemorizationActivePlanModel.statusPaused,
        updatedAt: now,
      );
    }).toList();

    await _savePlans(updatedPlans);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activePlanIdKey);
    await prefs.remove(_legacyActivePlanKey);
    await prefs.remove(_legacyTodayTaskKey);
  }

  static Future<void> reactivatePlan(String planId) async {
    if (planId.trim().isEmpty) return;

    final plans = await getPlans();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedExists = plans.any((plan) => plan.id == planId);
    if (!selectedExists) return;

    final updatedPlans = plans.map((plan) {
      return plan.copyWith(
        isActive: plan.id == planId,
        planStatus: plan.id == planId
            ? MemorizationActivePlanModel.statusActive
            : (plan.isCompleted
                  ? MemorizationActivePlanModel.statusCompleted
                  : MemorizationActivePlanModel.statusPaused),
        updatedAt: plan.id == planId ? now : plan.updatedAt,
      );
    }).toList();

    await _savePlans(updatedPlans);

    final activePlan = updatedPlans.firstWhere((plan) => plan.id == planId);
    final activeTask = await getTodayTaskForPlan(planId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePlanIdKey, activePlan.id);

    await prefs.setString(_legacyActivePlanKey, jsonEncode(activePlan.toMap()));

    if (activeTask != null) {
      // عند إعادة تفعيل خطة متوقفة، نعيد جدولتها من اليوم.
      // كده التقويم يبدأ يعرض الخطة من تاريخ الرجوع، مش من تاريخها القديم.
      final rescheduledTask = activeTask.copyWith(
        scheduledDate: today,
        updatedAt: now,
      );

      await _saveTaskForPlan(planId: activePlan.id, task: rescheduledTask);

      await prefs.setString(
        _legacyTodayTaskKey,
        jsonEncode(rescheduledTask.toMap()),
      );
    } else {
      await prefs.remove(_legacyTodayTaskKey);
    }
  }

  static Future<MemorizationTodayTaskModel?> getTodayTask() async {
    final activePlan = await getActivePlan();
    if (activePlan == null) return null;

    return getTodayTaskForPlan(activePlan.id);
  }

  static Future<MemorizationTodayTaskModel?> getTodayTaskForPlan(
    String planId,
  ) async {
    if (planId.trim().isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_taskKey(planId));

    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final task = MemorizationTodayTaskModel.fromMap(decoded);
      if (!task.hasValidRange) return null;

      return task;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateTodayTaskForActivePlan(
    MemorizationTodayTaskModel task,
  ) async {
    if (!task.hasValidRange) return;

    final activePlan = await getActivePlan();
    if (activePlan == null) return;

    final prefs = await SharedPreferences.getInstance();

    await _saveTaskForPlan(planId: activePlan.id, task: task);

    await prefs.setString(_legacyTodayTaskKey, jsonEncode(task.toMap()));

    await prefs.setString(_legacyActivePlanKey, jsonEncode(activePlan.toMap()));
  }

  static Future<void> updateTodayTaskStatusForActivePlan({
    required String taskId,
    required String status,
    bool? isCompleted,
  }) async {
    final activePlan = await getActivePlan();
    if (activePlan == null) return;

    final task = await getTodayTaskForPlan(activePlan.id);
    if (task == null || task.id != taskId) return;

    final updatedTask = task.copyWith(
      status: status,
      isCompleted: isCompleted ?? task.isCompleted,
      updatedAt: DateTime.now(),
    );

    await updateTodayTaskForActivePlan(updatedTask);
  }

  static Future<void> deletePlan(String planId) async {
    if (planId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final plans = await getPlans();

    final wasActive = plans.any((plan) => plan.id == planId && plan.isActive);

    final updatedPlans = plans.where((plan) => plan.id != planId).toList();
    await _savePlans(updatedPlans);

    await prefs.remove(_taskKey(planId));

    if (wasActive) {
      await prefs.remove(_activePlanIdKey);
      await prefs.remove(_legacyActivePlanKey);
      await prefs.remove(_legacyTodayTaskKey);
    }

    if (updatedPlans.isEmpty) {
      await _clearAllMemorizationRuntimeData(prefs);
    }
  }

  static Future<void> renamePlan({
    required String planId,
    required String planName,
  }) async {
    final cleanName = planName.trim();
    if (planId.trim().isEmpty || cleanName.isEmpty) return;

    final plans = await getPlans();

    final updatedPlans = plans.map((plan) {
      if (plan.id != planId) return plan;

      return plan.copyWith(planName: cleanName, updatedAt: DateTime.now());
    }).toList();

    await _savePlans(updatedPlans);

    final activePlan = await getActivePlan();
    if (activePlan?.id == planId) {
      final refreshed = updatedPlans.firstWhere((plan) => plan.id == planId);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _legacyActivePlanKey,
        jsonEncode(refreshed.toMap()),
      );
    }
  }

  static Future<void> saveUpdatedPlan(
    MemorizationActivePlanModel updatedPlan,
  ) async {
    final plans = await getPlans();
    if (!plans.any((plan) => plan.id == updatedPlan.id)) return;

    final updatedPlans = plans.map((plan) {
      if (plan.id != updatedPlan.id) return plan;
      return updatedPlan;
    }).toList();

    await _savePlans(updatedPlans);

    if (updatedPlan.isActive) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _legacyActivePlanKey,
        jsonEncode(updatedPlan.toMap()),
      );
    }
  }

  static Future<MemorizationActivePlanModel?> markPlanCompleted({
    required String planId,
    required DateTime completedAt,
    int? finalCourseScore,
  }) async {
    if (planId.trim().isEmpty) return null;

    final plans = await getPlans();
    if (!plans.any((plan) => plan.id == planId)) return null;

    final now = DateTime.now();
    MemorizationActivePlanModel? completedPlan;

    final updatedPlans = plans.map((plan) {
      if (plan.id != planId) return plan;

      completedPlan = plan.copyWith(
        isActive: plan.isActive,
        planStatus: MemorizationActivePlanModel.statusCompleted,
        completedAt: plan.completedAt ?? completedAt,
        finalCourseScore: finalCourseScore ?? plan.finalCourseScore,
        certificateGeneratedAt: plan.certificateGeneratedAt ?? now,
        updatedAt: now,
      );
      return completedPlan!;
    }).toList();

    await _savePlans(updatedPlans);

    final completed = completedPlan;
    if (completed != null && completed.isActive) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activePlanIdKey, completed.id);
      await prefs.setString(
        _legacyActivePlanKey,
        jsonEncode(completed.toMap()),
      );
    }

    return completed;
  }

  static Future<void> clearActivePlan() async {
    await stopActivePlan();
  }

  /// يستخدم عند حذف كل شيء من صفحة الحفظ.
  /// يمسح الخطط + مهام الخطط + نتائج الجلسات حتى الكالندر والتقدم يرجعوا فاضيين.
  static Future<void> clearAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearAllMemorizationRuntimeData(prefs);
  }

  static Future<void> _clearAllMemorizationRuntimeData(
    SharedPreferences prefs,
  ) async {
    final plans = await getPlans();

    for (final plan in plans) {
      await prefs.remove(_taskKey(plan.id));
    }

    final keys = prefs.getKeys().where((key) {
      return key.startsWith(_taskPrefix) ||
          key.startsWith('quran_memorization_progress_') ||
          key.startsWith('my_lessons_memorization_progress_') ||
          key.startsWith('memorization_progress_');
    }).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }

    await prefs.remove(_plansKey);
    await prefs.remove(_activePlanIdKey);
    await prefs.remove(_legacyActivePlanKey);
    await prefs.remove(_legacyTodayTaskKey);

    await MemorizationSessionResultStorage.clearResults();
  }

  static String _taskKey(String planId) {
    return '$_taskPrefix$planId';
  }

  static Future<void> _saveTaskForPlan({
    required String planId,
    required MemorizationTodayTaskModel task,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_taskKey(planId), jsonEncode(task.toMap()));
  }

  static Future<void> _migrateOldSinglePlanIfNeeded(
    SharedPreferences prefs,
  ) async {
    final existingPlans = prefs.getString(_plansKey);
    if (existingPlans != null && existingPlans.trim().isNotEmpty) {
      return;
    }

    final rawOldPlan = prefs.getString(_legacyActivePlanKey);
    final rawOldTask = prefs.getString(_legacyTodayTaskKey);

    if (rawOldPlan == null || rawOldPlan.trim().isEmpty) return;

    try {
      final decodedPlan = jsonDecode(rawOldPlan);
      if (decodedPlan is! Map<String, dynamic>) return;

      final oldPlan = MemorizationActivePlanModel.fromMap(decodedPlan);
      if (oldPlan.id.trim().isEmpty) return;

      final migratedPlan = oldPlan.copyWith(isActive: true);

      await prefs.setString(_plansKey, jsonEncode([migratedPlan.toMap()]));

      await prefs.setString(_activePlanIdKey, migratedPlan.id);

      if (rawOldTask != null && rawOldTask.trim().isNotEmpty) {
        await prefs.setString(_taskKey(migratedPlan.id), rawOldTask);
      }
    } catch (_) {}
  }

  static MemorizationTodayTaskModel _buildFirstTodayTask({
    required MemorizationPlanRequest request,
    required MemorizationActivePlanModel plan,
    required _GlobalRange range,
  }) {
    final now = DateTime.now();

    final bool hasNewMemorization =
        request.actionType == MemorizationActionType.newMemorization ||
        request.actionType == MemorizationActionType.newWithReview;

    final String type = hasNewMemorization ? 'dailyNew' : 'dailyReview';

    final int chunkSize = _firstTaskChunkSize(
      plan: plan,
      range: range,
      hasNewMemorization: hasNewMemorization,
    );

    final int taskStart = range.startGlobalAyahIndex;

    final int taskEnd = (taskStart + chunkSize - 1)
        .clamp(taskStart, range.endGlobalAyahIndex)
        .toInt();

    return MemorizationTodayTaskModel(
      id: 'today_task_${now.microsecondsSinceEpoch}',
      planId: plan.id,
      type: type,
      title: hasNewMemorization ? 'حفظ اليوم' : 'مراجعة اليوم',
      subtitle: hasNewMemorization
          ? 'حفظ ${taskEnd - taskStart + 1} آية'
          : 'مراجعة ${taskEnd - taskStart + 1} آية',
      scopeTitle: _scopeTitleFromRange(taskStart, taskEnd),
      startGlobalAyahIndex: taskStart,
      endGlobalAyahIndex: taskEnd,
      expectedMinutes: _estimateMinutes(
        newPages: hasNewMemorization ? plan.dailyNewPages : 0,
        reviewPages: plan.dailyReviewPages,
      ),
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  static int _firstTaskChunkSize({
    required MemorizationActivePlanModel plan,
    required _GlobalRange range,
    required bool hasNewMemorization,
  }) {
    final fullRange = range.endGlobalAyahIndex - range.startGlobalAyahIndex + 1;
    if (fullRange <= 0) return 1;

    final pages = hasNewMemorization
        ? plan.dailyNewPages
        : plan.dailyReviewPages;
    if (pages > 0) {
      final end = _endGlobalAyahFromPages(
        startGlobalAyahIndex: range.startGlobalAyahIndex,
        maxEndGlobalAyahIndex: range.endGlobalAyahIndex,
        pages: pages,
      );
      return (end - range.startGlobalAyahIndex + 1).clamp(1, fullRange).toInt();
    }

    return fullRange.clamp(1, 10).toInt();
  }

  static String _scopeTitleFromRange(
    int startGlobalAyahIndex,
    int endGlobalAyahIndex,
  ) {
    final start = QuranReaderHelpers.getPositionFromGlobalIndex(
      startGlobalAyahIndex.clamp(0, QuranReaderHelpers.totalAyahs - 1),
    );

    final end = QuranReaderHelpers.getPositionFromGlobalIndex(
      endGlobalAyahIndex.clamp(0, QuranReaderHelpers.totalAyahs - 1),
    );

    final startSurahName = QuranReaderHelpers.getSuraName(start.suraIndex);
    final endSurahName = QuranReaderHelpers.getSuraName(end.suraIndex);

    if (start.suraIndex == end.suraIndex) {
      return 'سورة $startSurahName • آية ${start.ayahIndex + 1} إلى ${end.ayahIndex + 1}';
    }

    return 'من سورة $startSurahName آية ${start.ayahIndex + 1} إلى سورة $endSurahName آية ${end.ayahIndex + 1}';
  }

  static _GlobalRange _buildTaskRange(MemorizationPlanRequest request) {
    return _buildRangeFromScope(request.scope);
  }

  static _GlobalRange _buildRangeFromScope(dynamic scope) {
    switch (scope.type) {
      case MemorizationScopeType.surah:
      case MemorizationScopeType.ayahs:
        return _buildSurahOrAyahRange(scope);

      case MemorizationScopeType.juz:
        final int? juzNumber = scope.juzNumber;

        if (juzNumber == null || juzNumber < 1 || juzNumber > 30) {
          return const _GlobalRange.invalid();
        }

        return _rangeFromJuz(juzNumber);

      case MemorizationScopeType.hizb:
        final int? hizbNumber = scope.hizbNumber;

        if (hizbNumber == null || hizbNumber < 1 || hizbNumber > 60) {
          return const _GlobalRange.invalid();
        }

        final hizbRange = QuranMemorizationHizbBoundaries.rangeForHizb(
          hizbNumber,
        );

        if (!hizbRange.isValid) return const _GlobalRange.invalid();

        return _GlobalRange(
          startGlobalAyahIndex: hizbRange.startGlobalAyahIndex,
          endGlobalAyahIndex: hizbRange.endGlobalAyahIndex,
        ).normalized();

      case MemorizationScopeType.pages:
        final int? fromPage = scope.fromPage;
        final int? toPage = scope.toPage;

        if (fromPage == null ||
            toPage == null ||
            fromPage < 1 ||
            toPage > 604 ||
            fromPage > toPage) {
          return const _GlobalRange.invalid();
        }

        return _rangeFromPages(fromPage: fromPage, toPage: toPage);

      case MemorizationScopeType.wholeQuran:
      case MemorizationScopeType.knownMemorized:
        return _GlobalRange(
          startGlobalAyahIndex: 0,
          endGlobalAyahIndex: QuranReaderHelpers.totalAyahs - 1,
        ).normalized();

      case MemorizationScopeType.weakSpots:
        return const _GlobalRange.invalid();
    }

    return const _GlobalRange.invalid();
  }

  static _GlobalRange _buildSurahOrAyahRange(dynamic scope) {
    final int? surahNumber = scope.surahNumber;

    if (surahNumber == null || surahNumber < 1 || surahNumber > 114) {
      return const _GlobalRange.invalid();
    }

    final int maxAyah = scope.totalAyahs > 0 ? scope.totalAyahs : 1;

    final int fromAyah = (scope.fromAyah ?? 1).clamp(1, maxAyah).toInt();

    final int toAyah = (scope.toAyah ?? maxAyah)
        .clamp(fromAyah, maxAyah)
        .toInt();

    return _rangeFromAyahs(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
  }

  static _GlobalRange _rangeFromAyahs({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
  }) {
    final int safeSurah = surahNumber.clamp(1, 114).toInt();

    final int start = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: safeSurah - 1,
      ayahIndex: math.max(0, fromAyah - 1),
    );

    final int end = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: safeSurah - 1,
      ayahIndex: math.max(0, toAyah - 1),
    );

    return _GlobalRange(
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end,
    ).normalized();
  }

  static _GlobalRange _rangeFromJuz(int juzNumber) {
    final int safeJuz = juzNumber.clamp(1, 30).toInt();

    final startJuz = QuranReaderHelpers.juzStarts[safeJuz - 1];

    final int start = QuranReaderHelpers.getGlobalAyahIndex(
      suraIndex: startJuz.suraIndex,
      ayahIndex: startJuz.ayahIndex,
    );

    final int end;
    if (safeJuz == 30) {
      end = QuranReaderHelpers.totalAyahs - 1;
    } else {
      final nextJuz = QuranReaderHelpers.juzStarts[safeJuz];
      end =
          QuranReaderHelpers.getGlobalAyahIndex(
            suraIndex: nextJuz.suraIndex,
            ayahIndex: nextJuz.ayahIndex,
          ) -
          1;
    }

    return _GlobalRange(
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end,
    ).normalized();
  }

  static _GlobalRange _rangeFromPages({
    required int fromPage,
    required int toPage,
  }) {
    final int safeFrom = fromPage.clamp(1, 604).toInt();
    final int safeTo = toPage.clamp(safeFrom, 604).toInt();

    final int start = QuranPageMapper.getGlobalAyahIndexForPage(safeFrom);

    final int end = safeTo >= 604
        ? QuranReaderHelpers.totalAyahs - 1
        : QuranPageMapper.getGlobalAyahIndexForPage(safeTo + 1) - 1;

    return _GlobalRange(
      startGlobalAyahIndex: start,
      endGlobalAyahIndex: end,
    ).normalized();
  }

  static int _hizbStartPage(int hizbNumber) {
    final int safe = hizbNumber.clamp(1, 60).toInt();
    return ((safe - 1) * 10 + 1).clamp(1, 604).toInt();
  }

  static int _hizbEndPage(int hizbNumber) {
    final int start = _hizbStartPage(hizbNumber);
    return (start + 9).clamp(start, 604).toInt();
  }

  static int _endGlobalAyahFromPages({
    required int startGlobalAyahIndex,
    required int maxEndGlobalAyahIndex,
    required double pages,
  }) {
    final double safePages = pages <= 0 ? 0.5 : pages;
    final int startPage = QuranPageMapper.getPageNumberForGlobalAyah(
      startGlobalAyahIndex,
    );

    if (safePages <= 0.5) {
      return _halfPageEnd(
        startGlobalAyahIndex: startGlobalAyahIndex,
        maxEndGlobalAyahIndex: maxEndGlobalAyahIndex,
      );
    }

    final int wholePages = safePages.floor();
    final bool hasHalfPage = safePages - wholePages >= 0.5;

    int endPage = startPage + wholePages - 1;
    if (endPage < startPage) endPage = startPage;
    if (endPage > 604) endPage = 604;

    int endGlobalAyahIndex = _pageEndGlobalAyahIndex(endPage);

    if (hasHalfPage && endGlobalAyahIndex < maxEndGlobalAyahIndex) {
      endGlobalAyahIndex = _halfPageEnd(
        startGlobalAyahIndex: endGlobalAyahIndex + 1,
        maxEndGlobalAyahIndex: maxEndGlobalAyahIndex,
      );
    }

    return endGlobalAyahIndex
        .clamp(startGlobalAyahIndex, maxEndGlobalAyahIndex)
        .toInt();
  }

  static int _halfPageEnd({
    required int startGlobalAyahIndex,
    required int maxEndGlobalAyahIndex,
  }) {
    final int page = QuranPageMapper.getPageNumberForGlobalAyah(
      startGlobalAyahIndex,
    );

    final int pageEnd = _pageEndGlobalAyahIndex(
      page,
    ).clamp(startGlobalAyahIndex, maxEndGlobalAyahIndex).toInt();

    final int availableAyahs = pageEnd - startGlobalAyahIndex + 1;
    final int halfAyahs = math.max(1, (availableAyahs / 2).ceil());

    return (startGlobalAyahIndex + halfAyahs - 1)
        .clamp(startGlobalAyahIndex, maxEndGlobalAyahIndex)
        .toInt();
  }

  static int _pageEndGlobalAyahIndex(int pageNumber) {
    final int safePage = pageNumber.clamp(1, 604).toInt();

    if (safePage >= 604) {
      return QuranReaderHelpers.totalAyahs - 1;
    }

    return QuranPageMapper.getGlobalAyahIndexForPage(safePage + 1) - 1;
  }

  static int _estimateMinutes({
    required double newPages,
    required double reviewPages,
  }) {
    final double minutes = (newPages * 12) + (reviewPages * 6) + 5;
    return minutes.clamp(8, 60).round();
  }
}

class _GlobalRange {
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;

  const _GlobalRange({
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
  });

  const _GlobalRange.invalid()
    : startGlobalAyahIndex = -1,
      endGlobalAyahIndex = -1;

  bool get isValid {
    return startGlobalAyahIndex >= 0 &&
        endGlobalAyahIndex >= startGlobalAyahIndex;
  }

  _GlobalRange normalized() {
    if (!isValid) return this;

    final int maxIndex = QuranReaderHelpers.totalAyahs - 1;

    final int start = startGlobalAyahIndex.clamp(0, maxIndex).toInt();
    final int end = endGlobalAyahIndex.clamp(start, maxIndex).toInt();

    return _GlobalRange(startGlobalAyahIndex: start, endGlobalAyahIndex: end);
  }
}
