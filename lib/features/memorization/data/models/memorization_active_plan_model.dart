import 'memorization_plan_preview_model.dart';
import 'planning/memorization_plan_intensity.dart';
import 'memorization_plan_request.dart';
import 'memorization_test_preferences.dart';

class MemorizationActivePlanModel {
  static const String statusActive = 'active';
  static const String statusPaused = 'paused';
  static const String statusCompleted = 'completed';

  final String id;

  /// اسم الخطة الذي يظهر للمستخدم.
  final String planName;

  final String userTypeName;
  final String actionTypeName;
  final String scopeTypeName;
  final String calculationMethodName;

  final String pathTitle;
  final String scopeTitle;
  final String scopeSizeText;
  final String calculationText;

  final String durationText;
  final String dailyNewText;
  final String dailyBaseReviewText;
  final String weakReviewText;
  final String selfTestText;
  final String loadText;

  final int totalDays;
  final int totalAyahs;
  final int totalPages;
  final int targetLearningDays;
  final int learningSessionsCount;
  final int effectiveCalendarDays;
  final String intensityModeName;
  final int planVersion;
  final int dailyNewAyahs;
  final double dailyNewPages;
  final double dailyReviewPages;

  /// نطاق الحفظ/المراجعة الأساسي داخل القرآن كله.
  final int scopeStartGlobalAyahIndex;
  final int scopeEndGlobalAyahIndex;

  /// نطاق المراجعة المستقل لو المستخدم اختار حفظ + مراجعة وفيه محفوظ سابق.
  final int reviewStartGlobalAyahIndex;
  final int reviewEndGlobalAyahIndex;
  final String reviewScopeTitle;

  /// true = المراجعة من الذي حفظه داخل نفس الخطة فقط.
  final bool reviewFromLearnedOnly;

  /// true = التطبيق يختار وتيرة المراجعة تلقائيًا حسب الخطة.
  final bool smartReviewDistribution;

  /// بعد كل كام جلسة أساسية تظهر مهمة المراجعة عند التوزيع اليدوي.
  final int reviewEveryDays;

  /// عدد جلسات المراجعة المطلوبة لإنهاء نطاق المراجعة.
  final int reviewSessionsCount;

  /// عدد الأيام الفعلية على التقويم بعد احترام تكرار المراجعة.
  final int effectiveReviewDays;

  /// ملاحظة توضح هل تم تمديد المراجعة لتجنب الضغط.
  final String reviewScheduleNote;

  /// عدد اختبارات الخطة المخطط توزيعها حسب حجم النطاق.
  final int plannedTestsCount;

  /// إعدادات شكل الاختبار. عدد الاختبارات نفسه يحدده النظام.
  final MemorizationTestPreferences testPreferences;

  /// عدد أيام الراحة أسبوعيًا. يتم توزيعها تلقائيًا بدون أيام متتالية.
  final int weeklyRestDays;

  final bool isActive;
  final String planStatus;
  final DateTime? completedAt;
  final int? finalCourseScore;
  final DateTime? certificateGeneratedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemorizationActivePlanModel({
    required this.id,
    required this.planName,
    required this.userTypeName,
    required this.actionTypeName,
    required this.scopeTypeName,
    required this.calculationMethodName,
    required this.pathTitle,
    required this.scopeTitle,
    required this.scopeSizeText,
    required this.calculationText,
    required this.durationText,
    required this.dailyNewText,
    required this.dailyBaseReviewText,
    required this.weakReviewText,
    required this.selfTestText,
    required this.loadText,
    required this.totalDays,
    required this.totalAyahs,
    required this.totalPages,
    required this.targetLearningDays,
    required this.learningSessionsCount,
    required this.effectiveCalendarDays,
    required this.intensityModeName,
    required this.planVersion,
    required this.dailyNewAyahs,
    required this.dailyNewPages,
    required this.dailyReviewPages,
    required this.scopeStartGlobalAyahIndex,
    required this.scopeEndGlobalAyahIndex,
    required this.reviewStartGlobalAyahIndex,
    required this.reviewEndGlobalAyahIndex,
    required this.reviewScopeTitle,
    required this.reviewFromLearnedOnly,
    required this.smartReviewDistribution,
    required this.reviewEveryDays,
    required this.reviewSessionsCount,
    required this.effectiveReviewDays,
    required this.reviewScheduleNote,
    required this.plannedTestsCount,
    required this.testPreferences,
    required this.weeklyRestDays,
    required this.isActive,
    this.planStatus = statusActive,
    this.completedAt,
    this.finalCourseScore,
    this.certificateGeneratedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemorizationActivePlanModel.fromRequest({
    required MemorizationPlanRequest request,
    required MemorizationPlanPreviewModel preview,
    String? planName,
    int scopeStartGlobalAyahIndex = 0,
    int scopeEndGlobalAyahIndex = 0,
    int? reviewStartGlobalAyahIndex,
    int? reviewEndGlobalAyahIndex,
    String? reviewScopeTitle,
  }) {
    final now = DateTime.now();

    final String cleanPlanName = (planName ?? '').trim();
    final String generatedPlanName = _generatePlanName(
      pathTitle: preview.pathTitle,
      scopeTitle: preview.scopeTitle,
    );

    final bool reviewLearnedOnly = request.reviewFromLearnedOnly;
    final int reviewStart =
        reviewStartGlobalAyahIndex ?? scopeStartGlobalAyahIndex;
    final int reviewEnd = reviewEndGlobalAyahIndex ?? scopeEndGlobalAyahIndex;
    final reviewSchedule = _buildReviewSchedule(
      request: request,
      preview: preview,
      reviewStart: reviewStart,
      reviewEnd: reviewEnd < reviewStart ? reviewStart : reviewEnd,
    );

    return MemorizationActivePlanModel(
      id: 'memorization_plan_${now.microsecondsSinceEpoch}',
      planName: cleanPlanName.isEmpty ? generatedPlanName : cleanPlanName,
      userTypeName: request.userType.name,
      actionTypeName: request.actionType.name,
      scopeTypeName: request.scope.type.name,
      calculationMethodName: request.calculationMethod.name,
      pathTitle: preview.pathTitle,
      scopeTitle: preview.scopeTitle,
      scopeSizeText: preview.scopeSizeText,
      calculationText: preview.calculationText,
      durationText: preview.durationText,
      dailyNewText: preview.dailyNewText,
      dailyBaseReviewText: preview.dailyBaseReviewText,
      weakReviewText: preview.weakReviewText,
      selfTestText: preview.selfTestText,
      loadText: preview.loadText,
      totalDays: preview.totalDays,
      totalAyahs: preview.totalAyahs,
      totalPages: preview.totalPages,
      targetLearningDays: preview.targetLearningDays,
      learningSessionsCount: preview.learningSessionsCount,
      effectiveCalendarDays: preview.effectiveCalendarDays,
      intensityModeName: preview.intensity.code,
      planVersion: 1,
      dailyNewAyahs: 0,
      dailyNewPages: preview.dailyNewPages,
      dailyReviewPages: preview.dailyReviewPages,
      scopeStartGlobalAyahIndex: scopeStartGlobalAyahIndex,
      scopeEndGlobalAyahIndex: scopeEndGlobalAyahIndex,
      reviewStartGlobalAyahIndex: reviewStart,
      reviewEndGlobalAyahIndex: reviewEnd < reviewStart
          ? reviewStart
          : reviewEnd,
      reviewScopeTitle: reviewLearnedOnly
          ? 'ما حفظته في هذه الخطة'
          : (reviewScopeTitle?.trim().isNotEmpty == true
                ? reviewScopeTitle!.trim()
                : request.reviewScope?.rangeText ?? 'نطاق المراجعة'),
      reviewFromLearnedOnly: reviewLearnedOnly,
      smartReviewDistribution: request.usesSmartReviewDistribution,
      reviewEveryDays: request.safeReviewEveryDays,
      reviewSessionsCount: reviewSchedule.sessionsCount,
      effectiveReviewDays: reviewSchedule.effectiveDays,
      reviewScheduleNote: reviewSchedule.note,
      plannedTestsCount: preview.plannedTestsCount.clamp(0, 99).toInt(),
      testPreferences: request.testPreferences,
      weeklyRestDays: request.safeWeeklyRestDays,
      isActive: true,
      planStatus: statusActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  static _ReviewScheduleInfo _buildReviewSchedule({
    required MemorizationPlanRequest request,
    required MemorizationPlanPreviewModel preview,
    required int reviewStart,
    required int reviewEnd,
  }) {
    final int every = request.usesSmartReviewDistribution
        ? _suggestSmartReviewEvery(request: request, preview: preview)
        : request.safeReviewEveryDays;
    final int totalReviewAyahs = (reviewEnd - reviewStart + 1)
        .clamp(1, 999999)
        .toInt();
    final double pages = preview.dailyReviewPages <= 0
        ? 0.5
        : preview.dailyReviewPages;

    int sessions = request.safeReviewTargetDays ?? 0;
    if (sessions <= 0) {
      // الصفحة في المصحف المدني حوالي 15 سطرًا، لكن عدد الآيات يختلف جدًا.
      // لذلك نستخدم dailyReviewPages المخزنة لتحديد جلسات تقريبية، لا لتقطيع النص.
      final roughPages = (totalReviewAyahs / 10).clamp(1, 604).toDouble();
      sessions = (roughPages / pages).ceil().clamp(1, 999).toInt();
    }

    final int effectiveDays = 1 + ((sessions - 1) * every);
    final String note = every <= 1
        ? 'المراجعة موزعة على $sessions جلسة يومية.'
        : 'اخترت $sessions جلسة مراجعة كل $every أيام؛ لذلك مددنا التقويم إلى $effectiveDays يوم حتى لا تتكدس المراجعة.';

    return _ReviewScheduleInfo(
      sessionsCount: sessions,
      effectiveDays: effectiveDays,
      note: note,
    );
  }

  static int _suggestSmartReviewEvery({
    required MemorizationPlanRequest request,
    required MemorizationPlanPreviewModel preview,
  }) {
    final int days = preview.totalDays <= 0 ? 30 : preview.totalDays;

    if (request.reviewFromLearnedOnly) {
      if (days <= 10) return 2;
      if (days <= 30) return 3;
      return 4;
    }

    final sessions = request.safeReviewTargetDays;
    if (sessions != null && sessions > 0) {
      final every = (days / (sessions + 1)).floor();
      return every.clamp(2, 6).toInt();
    }

    if (days <= 20) return 2;
    if (days <= 60) return 3;
    return 4;
  }

  static String _generatePlanName({
    required String pathTitle,
    required String scopeTitle,
  }) {
    final cleanPath = pathTitle.trim();
    final cleanScope = scopeTitle.trim();

    if (cleanPath.isEmpty && cleanScope.isEmpty) return 'خطة حفظ جديدة';
    if (cleanPath.isEmpty) return cleanScope;
    if (cleanScope.isEmpty) return cleanPath;

    return '$cleanPath - $cleanScope';
  }

  MemorizationActivePlanModel copyWith({
    String? id,
    String? planName,
    String? userTypeName,
    String? actionTypeName,
    String? scopeTypeName,
    String? calculationMethodName,
    String? pathTitle,
    String? scopeTitle,
    String? scopeSizeText,
    String? calculationText,
    String? durationText,
    String? dailyNewText,
    String? dailyBaseReviewText,
    String? weakReviewText,
    String? selfTestText,
    String? loadText,
    int? totalDays,
    int? totalAyahs,
    int? totalPages,
    int? targetLearningDays,
    int? learningSessionsCount,
    int? effectiveCalendarDays,
    String? intensityModeName,
    int? planVersion,
    int? dailyNewAyahs,
    double? dailyNewPages,
    double? dailyReviewPages,
    int? scopeStartGlobalAyahIndex,
    int? scopeEndGlobalAyahIndex,
    int? reviewStartGlobalAyahIndex,
    int? reviewEndGlobalAyahIndex,
    String? reviewScopeTitle,
    bool? reviewFromLearnedOnly,
    bool? smartReviewDistribution,
    int? reviewEveryDays,
    int? reviewSessionsCount,
    int? effectiveReviewDays,
    String? reviewScheduleNote,
    int? plannedTestsCount,
    MemorizationTestPreferences? testPreferences,
    int? weeklyRestDays,
    bool? isActive,
    String? planStatus,
    DateTime? completedAt,
    int? finalCourseScore,
    DateTime? certificateGeneratedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemorizationActivePlanModel(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      userTypeName: userTypeName ?? this.userTypeName,
      actionTypeName: actionTypeName ?? this.actionTypeName,
      scopeTypeName: scopeTypeName ?? this.scopeTypeName,
      calculationMethodName:
          calculationMethodName ?? this.calculationMethodName,
      pathTitle: pathTitle ?? this.pathTitle,
      scopeTitle: scopeTitle ?? this.scopeTitle,
      scopeSizeText: scopeSizeText ?? this.scopeSizeText,
      calculationText: calculationText ?? this.calculationText,
      durationText: durationText ?? this.durationText,
      dailyNewText: dailyNewText ?? this.dailyNewText,
      dailyBaseReviewText: dailyBaseReviewText ?? this.dailyBaseReviewText,
      weakReviewText: weakReviewText ?? this.weakReviewText,
      selfTestText: selfTestText ?? this.selfTestText,
      loadText: loadText ?? this.loadText,
      totalDays: totalDays ?? this.totalDays,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      totalPages: totalPages ?? this.totalPages,
      targetLearningDays: targetLearningDays ?? this.targetLearningDays,
      learningSessionsCount:
          learningSessionsCount ?? this.learningSessionsCount,
      effectiveCalendarDays:
          effectiveCalendarDays ?? this.effectiveCalendarDays,
      intensityModeName: intensityModeName ?? this.intensityModeName,
      planVersion: planVersion ?? this.planVersion,
      dailyNewAyahs: dailyNewAyahs ?? this.dailyNewAyahs,
      dailyNewPages: dailyNewPages ?? this.dailyNewPages,
      dailyReviewPages: dailyReviewPages ?? this.dailyReviewPages,
      scopeStartGlobalAyahIndex:
          scopeStartGlobalAyahIndex ?? this.scopeStartGlobalAyahIndex,
      scopeEndGlobalAyahIndex:
          scopeEndGlobalAyahIndex ?? this.scopeEndGlobalAyahIndex,
      reviewStartGlobalAyahIndex:
          reviewStartGlobalAyahIndex ?? this.reviewStartGlobalAyahIndex,
      reviewEndGlobalAyahIndex:
          reviewEndGlobalAyahIndex ?? this.reviewEndGlobalAyahIndex,
      reviewScopeTitle: reviewScopeTitle ?? this.reviewScopeTitle,
      reviewFromLearnedOnly:
          reviewFromLearnedOnly ?? this.reviewFromLearnedOnly,
      smartReviewDistribution:
          smartReviewDistribution ?? this.smartReviewDistribution,
      reviewEveryDays: reviewEveryDays ?? this.reviewEveryDays,
      reviewSessionsCount: reviewSessionsCount ?? this.reviewSessionsCount,
      effectiveReviewDays: effectiveReviewDays ?? this.effectiveReviewDays,
      reviewScheduleNote: reviewScheduleNote ?? this.reviewScheduleNote,
      plannedTestsCount: plannedTestsCount ?? this.plannedTestsCount,
      testPreferences: testPreferences ?? this.testPreferences,
      weeklyRestDays: (weeklyRestDays ?? this.weeklyRestDays)
          .clamp(0, 3)
          .toInt(),
      isActive: isActive ?? this.isActive,
      planStatus: planStatus ?? this.planStatus,
      completedAt: completedAt ?? this.completedAt,
      finalCourseScore: finalCourseScore ?? this.finalCourseScore,
      certificateGeneratedAt:
          certificateGeneratedAt ?? this.certificateGeneratedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCompleted {
    return planStatus == statusCompleted || completedAt != null;
  }

  bool get isPaused {
    return !isActive && !isCompleted;
  }

  bool get hasValidScopeRange {
    return scopeStartGlobalAyahIndex >= 0 &&
        scopeEndGlobalAyahIndex >= scopeStartGlobalAyahIndex;
  }

  bool get hasValidReviewRange {
    return reviewStartGlobalAyahIndex >= 0 &&
        reviewEndGlobalAyahIndex >= reviewStartGlobalAyahIndex;
  }

  MemorizationPlanIntensity get intensity {
    return MemorizationPlanIntensityX.fromCode(intensityModeName);
  }

  int get currentPlanDay {
    final elapsed =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .difference(
              DateTime(createdAt.year, createdAt.month, createdAt.day),
            )
            .inDays +
        1;
    return elapsed.clamp(1, effectiveCalendarDays.clamp(1, 99999)).toInt();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planName': planName,
      'userTypeName': userTypeName,
      'actionTypeName': actionTypeName,
      'scopeTypeName': scopeTypeName,
      'calculationMethodName': calculationMethodName,
      'pathTitle': pathTitle,
      'scopeTitle': scopeTitle,
      'scopeSizeText': scopeSizeText,
      'calculationText': calculationText,
      'durationText': durationText,
      'dailyNewText': dailyNewText,
      'dailyBaseReviewText': dailyBaseReviewText,
      'weakReviewText': weakReviewText,
      'selfTestText': selfTestText,
      'loadText': loadText,
      'totalDays': totalDays,
      'totalAyahs': totalAyahs,
      'totalPages': totalPages,
      'targetLearningDays': targetLearningDays,
      'learningSessionsCount': learningSessionsCount,
      'effectiveCalendarDays': effectiveCalendarDays,
      'intensityModeName': intensityModeName,
      'planVersion': planVersion,
      'dailyNewAyahs': dailyNewAyahs,
      'dailyNewPages': dailyNewPages,
      'dailyReviewPages': dailyReviewPages,
      'scopeStartGlobalAyahIndex': scopeStartGlobalAyahIndex,
      'scopeEndGlobalAyahIndex': scopeEndGlobalAyahIndex,
      'reviewStartGlobalAyahIndex': reviewStartGlobalAyahIndex,
      'reviewEndGlobalAyahIndex': reviewEndGlobalAyahIndex,
      'reviewScopeTitle': reviewScopeTitle,
      'reviewFromLearnedOnly': reviewFromLearnedOnly,
      'smartReviewDistribution': smartReviewDistribution,
      'reviewEveryDays': reviewEveryDays,
      'reviewSessionsCount': reviewSessionsCount,
      'effectiveReviewDays': effectiveReviewDays,
      'reviewScheduleNote': reviewScheduleNote,
      'plannedTestsCount': plannedTestsCount,
      'testPreferences': testPreferences.toMap(),
      'weeklyRestDays': weeklyRestDays,
      'isActive': isActive,
      'planStatus': isCompleted
          ? statusCompleted
          : (isActive ? statusActive : statusPaused),
      'completedAt': completedAt?.toIso8601String(),
      'finalCourseScore': finalCourseScore,
      'certificateGeneratedAt': certificateGeneratedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemorizationActivePlanModel.fromMap(Map<String, dynamic> map) {
    final String pathTitle = map['pathTitle']?.toString() ?? '';
    final String scopeTitle = map['scopeTitle']?.toString() ?? '';

    final int start =
        int.tryParse(map['scopeStartGlobalAyahIndex']?.toString() ?? '') ?? 0;
    final int end =
        int.tryParse(map['scopeEndGlobalAyahIndex']?.toString() ?? '') ??
        ((int.tryParse(map['totalAyahs']?.toString() ?? '') ?? 1) - 1);

    final int reviewStart =
        int.tryParse(map['reviewStartGlobalAyahIndex']?.toString() ?? '') ??
        start;
    final int reviewEnd =
        int.tryParse(map['reviewEndGlobalAyahIndex']?.toString() ?? '') ?? end;
    final int legacyTotalDays =
        int.tryParse(map['totalDays']?.toString() ?? '') ?? 0;
    final int totalPages =
        int.tryParse(map['totalPages']?.toString() ?? '') ?? 0;
    final double dailyNewPages =
        double.tryParse(map['dailyNewPages']?.toString() ?? '') ?? 0;
    final int targetLearningDays =
        int.tryParse(map['targetLearningDays']?.toString() ?? '') ??
        legacyTotalDays;
    final DateTime? completedAt = DateTime.tryParse(
      map['completedAt']?.toString() ?? '',
    );
    final DateTime? certificateGeneratedAt = DateTime.tryParse(
      map['certificateGeneratedAt']?.toString() ?? '',
    );
    final int derivedSessions = totalPages > 0 && dailyNewPages > 0
        ? (totalPages / dailyNewPages).ceil()
        : targetLearningDays;
    final intensity =
        map['intensityModeName']?.toString().trim().isNotEmpty == true
        ? MemorizationPlanIntensityX.fromCode(
            map['intensityModeName']?.toString(),
          )
        : const MemorizationPlanIntensityResolver().resolve(
            totalPages: totalPages,
            targetLearningDays: targetLearningDays,
          );

    return MemorizationActivePlanModel(
      id: map['id']?.toString() ?? '',
      planName: map['planName']?.toString().trim().isNotEmpty == true
          ? map['planName'].toString()
          : _generatePlanName(pathTitle: pathTitle, scopeTitle: scopeTitle),
      userTypeName: map['userTypeName']?.toString() ?? '',
      actionTypeName: map['actionTypeName']?.toString() ?? '',
      scopeTypeName: map['scopeTypeName']?.toString() ?? '',
      calculationMethodName: map['calculationMethodName']?.toString() ?? '',
      pathTitle: pathTitle,
      scopeTitle: scopeTitle,
      scopeSizeText: map['scopeSizeText']?.toString() ?? '',
      calculationText: map['calculationText']?.toString() ?? '',
      durationText: map['durationText']?.toString() ?? '',
      dailyNewText: map['dailyNewText']?.toString() ?? '',
      dailyBaseReviewText: map['dailyBaseReviewText']?.toString() ?? '',
      weakReviewText: map['weakReviewText']?.toString() ?? '',
      selfTestText: map['selfTestText']?.toString() ?? '',
      loadText: map['loadText']?.toString() ?? '',
      totalDays: legacyTotalDays,
      totalAyahs: int.tryParse(map['totalAyahs']?.toString() ?? '') ?? 0,
      totalPages: totalPages,
      targetLearningDays: targetLearningDays,
      learningSessionsCount:
          (int.tryParse(map['learningSessionsCount']?.toString() ?? '') ??
                  derivedSessions)
              .clamp(1, 99999)
              .toInt(),
      effectiveCalendarDays:
          (int.tryParse(map['effectiveCalendarDays']?.toString() ?? '') ??
                  legacyTotalDays)
              .clamp(1, 99999)
              .toInt(),
      intensityModeName: intensity.code,
      planVersion: (int.tryParse(map['planVersion']?.toString() ?? '') ?? 1)
          .clamp(1, 99999)
          .toInt(),
      dailyNewAyahs: int.tryParse(map['dailyNewAyahs']?.toString() ?? '') ?? 0,
      dailyNewPages: dailyNewPages,
      dailyReviewPages:
          double.tryParse(map['dailyReviewPages']?.toString() ?? '') ?? 0,
      scopeStartGlobalAyahIndex: start,
      scopeEndGlobalAyahIndex: end < start ? start : end,
      reviewStartGlobalAyahIndex: reviewStart,
      reviewEndGlobalAyahIndex: reviewEnd < reviewStart
          ? reviewStart
          : reviewEnd,
      reviewScopeTitle:
          map['reviewScopeTitle']?.toString().trim().isNotEmpty == true
          ? map['reviewScopeTitle'].toString()
          : 'ما حفظته في هذه الخطة',
      reviewFromLearnedOnly: map['reviewFromLearnedOnly'] != false,
      smartReviewDistribution: map['smartReviewDistribution'] != false,
      reviewEveryDays:
          (int.tryParse(map['reviewEveryDays']?.toString() ?? '') ?? 1)
              .clamp(1, 7)
              .toInt(),
      reviewSessionsCount:
          (int.tryParse(map['reviewSessionsCount']?.toString() ?? '') ?? 1)
              .clamp(1, 999)
              .toInt(),
      effectiveReviewDays:
          (int.tryParse(map['effectiveReviewDays']?.toString() ?? '') ?? 1)
              .clamp(1, 9999)
              .toInt(),
      reviewScheduleNote: map['reviewScheduleNote']?.toString() ?? '',
      plannedTestsCount:
          (int.tryParse(map['plannedTestsCount']?.toString() ?? '') ?? 0)
              .clamp(0, 99)
              .toInt(),
      testPreferences: MemorizationTestPreferences.fromMap(
        map['testPreferences'],
      ),
      weeklyRestDays:
          (int.tryParse(map['weeklyRestDays']?.toString() ?? '') ?? 0)
              .clamp(0, 3)
              .toInt(),
      isActive: map['isActive'] != false,
      planStatus: _readPlanStatus(map, completedAt: completedAt),
      completedAt: completedAt,
      finalCourseScore: int.tryParse(
        map['finalCourseScore']?.toString() ?? '',
      )?.clamp(0, 100).toInt(),
      certificateGeneratedAt: certificateGeneratedAt,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static String _readPlanStatus(
    Map<String, dynamic> map, {
    required DateTime? completedAt,
  }) {
    final raw = map['planStatus']?.toString().trim();
    if (raw == statusActive || raw == statusPaused || raw == statusCompleted) {
      return raw!;
    }

    if (completedAt != null) {
      return statusCompleted;
    }

    return map['isActive'] == false ? statusPaused : statusActive;
  }
}

class _ReviewScheduleInfo {
  final int sessionsCount;
  final int effectiveDays;
  final String note;

  const _ReviewScheduleInfo({
    required this.sessionsCount,
    required this.effectiveDays,
    required this.note,
  });
}
