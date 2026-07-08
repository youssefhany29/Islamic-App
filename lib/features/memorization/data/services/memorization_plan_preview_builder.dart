import 'dart:math' as math;

import '../models/memorization_action_type.dart';
import '../models/memorization_calculation_method.dart';
import '../models/memorization_plan_preview_model.dart';
import '../models/planning/memorization_plan_intensity.dart';
import '../models/memorization_plan_request.dart';
import '../models/memorization_scope_option.dart';
import '../models/memorization_user_type.dart';

class MemorizationPlanPreviewBuilder {
  const MemorizationPlanPreviewBuilder();

  MemorizationPlanPreviewModel build(MemorizationPlanRequest request) {
    final bool includesNew = request.includesNewMemorization;

    final int totalAyahs = request.scope.totalAyahs;
    final int totalPages = request.scope.totalPages;
    final int reviewTotalPages = _reviewTotalPages(request, totalPages);

    final bool preferAyahCalculation = _preferAyahCalculation(request);

    final _PlanDailyLoad dailyLoad = _buildDailyLoad(
      request: request,
      preferAyahCalculation: preferAyahCalculation,
      totalAyahs: totalAyahs,
      totalPages: totalPages,
    );

    final int totalDays = _calculateTotalDays(
      request: request,
      dailyLoad: dailyLoad,
      preferAyahCalculation: preferAyahCalculation,
      totalAyahs: totalAyahs,
      totalPages: totalPages,
    );
    final intensityResolver = const MemorizationPlanIntensityResolver();
    final intensity = intensityResolver.resolve(
      totalPages: totalPages,
      targetLearningDays: totalDays,
    );
    final learningSessionsCount = includesNew
        ? intensityResolver.learningSessionsCount(
            totalPages: totalPages,
            targetLearningDays: totalDays,
            requestedDailyPages: dailyLoad.dailyPages,
            intensity: intensity,
          )
        : totalDays;

    final double baseReviewPages = _calculateBaseReviewPages(
      request: request,
      totalPages: totalPages,
      reviewTotalPages: reviewTotalPages,
      totalDays: totalDays,
      dailyLoad: dailyLoad,
    );

    final int reviewCalendarDays = _effectiveReviewCalendarDays(
      request: request,
      reviewTotalPages: reviewTotalPages,
      baseReviewPages: baseReviewPages,
    );

    final int reviewExtraDays = _extraReviewDaysForSeparateCalendar(
      request: request,
      newMemorizationDays: totalDays,
      reviewCalendarDays: reviewCalendarDays,
      reviewTotalPages: reviewTotalPages,
      baseReviewPages: baseReviewPages,
    );

    final int baseCalendarDays = totalDays + reviewExtraDays;
    final int restExtraDays = _restDaysExtra(
      calendarDays: baseCalendarDays,
      weeklyRestDays: request.safeWeeklyRestDays,
    );
    final int expectedTestsCount = _expectedTestsCount(
      request: request,
      totalDays: baseCalendarDays,
      totalPages: totalPages,
    );

    final int extraTestDays = math.max(0, expectedTestsCount);
    final int effectiveTotalDays =
        baseCalendarDays + restExtraDays + extraTestDays;

    return MemorizationPlanPreviewModel(
      pathTitle: _pathTitle(request),
      scopeTitle: request.scope.rangeText,
      scopeSizeText: request.scope.sizeText,
      calculationText: request.calculationMethod.title,
      durationText: _durationText(
        baseCalendarDays: baseCalendarDays,
        effectiveTotalDays: effectiveTotalDays,
        testsCount: expectedTestsCount,
        hasReview: request.includesScheduledReview,
        restDays: request.safeWeeklyRestDays,
      ),
      dailyNewText: includesNew
          ? _dailyNewText(
              preferAyahCalculation: preferAyahCalculation,
              dailyAyahs: dailyLoad.dailyAyahs,
              dailyPages: dailyLoad.dailyPages,
              totalAyahs: totalAyahs,
              totalPages: totalPages,
            )
          : 'لا يوجد حفظ جديد الآن',
      dailyBaseReviewText: _dailyReviewText(
        request: request,
        baseReviewPages: baseReviewPages,
        reviewTotalPages: reviewTotalPages,
      ),
      weakReviewText: 'مراجعة قريبة للمواضع الضعيفة فقط.',
      selfTestText: _selfTestText(
        totalDays: totalDays,
        includeTests: request.includesPlannedTests,
      ),
      loadText: _loadText(
        newPages: includesNew ? dailyLoad.dailyPages : 0,
        reviewPages: baseReviewPages,
      ),
      totalDays: totalDays,
      totalAyahs: totalAyahs,
      totalPages: totalPages,
      targetLearningDays: totalDays,
      learningSessionsCount: learningSessionsCount,
      effectiveCalendarDays: effectiveTotalDays,
      plannedTestsCount: expectedTestsCount,
      intensity: intensity,
      intensityWarningText: intensityResolver.warningText(
        totalPages: totalPages,
        targetLearningDays: totalDays,
        intensity: intensity,
      ),
      dailyNewAyahs: 0,
      dailyNewPages: includesNew ? dailyLoad.dailyPages : 0,
      dailyReviewPages: baseReviewPages,
      systemPoints: _systemPoints(request),
      reviewRules: const [
        'ابدأ بالمهمة الظاهرة لك اليوم فقط.',
        'أيام الاختبار تكون للاختبار فقط بدون ضغط زائد.',
        'المواضع الضعيفة ترجع لك في مراجعة قصيرة.',
      ],
    );
  }

  int _restDaysExtra({required int calendarDays, required int weeklyRestDays}) {
    final rest = weeklyRestDays.clamp(0, 3).toInt();
    if (rest <= 0 || calendarDays <= 0) return 0;

    final weeks = (calendarDays / 7).ceil();
    return weeks * rest;
  }

  String _durationText({
    required int baseCalendarDays,
    required int effectiveTotalDays,
    required int testsCount,
    required bool hasReview,
    required int restDays,
  }) {
    if (effectiveTotalDays <= baseCalendarDays) {
      return '$baseCalendarDays يوم تقريبًا';
    }

    final reasons = <String>[];
    if (testsCount > 0) reasons.add('الاختبارات');
    if (hasReview) reasons.add('المراجعة');
    if (restDays > 0) reasons.add('أيام الراحة');

    final reasonText = reasons.isEmpty ? 'تنظيم الرحلة' : reasons.join(' و');
    return '$effectiveTotalDays يوم تقريبًا، زادت قليلًا بسبب $reasonText';
  }

  bool _preferAyahCalculation(MemorizationPlanRequest request) {
    return false;
  }

  _PlanDailyLoad _buildDailyLoad({
    required MemorizationPlanRequest request,
    required bool preferAyahCalculation,
    required int totalAyahs,
    required int totalPages,
  }) {
    final int targetDays = _safeTargetDays(request.targetDays);

    if (request.calculationMethod ==
        MemorizationCalculationMethod.finishByDuration) {
      final double pages = _roundToHalfPage(
        totalPages / math.max(1, targetDays),
      );
      return _PlanDailyLoad(dailyAyahs: 0, dailyPages: math.max(0.5, pages));
    }

    if (request.calculationMethod ==
        MemorizationCalculationMethod.dailyAmount) {
      final pages =
          request.dailyPages ??
          _suggestDailyPages(
            request.userType,
            totalPages,
            review: request.isReviewPlan,
            newMem: request.includesNewMemorization,
          );

      return _PlanDailyLoad(dailyAyahs: 0, dailyPages: math.max(0.5, pages));
    }

    return _PlanDailyLoad(
      dailyAyahs: 0,
      dailyPages: _suggestDailyPages(
        request.userType,
        totalPages,
        review: request.isReviewPlan,
        newMem: request.includesNewMemorization,
      ),
    );
  }

  int _calculateTotalDays({
    required MemorizationPlanRequest request,
    required _PlanDailyLoad dailyLoad,
    required bool preferAyahCalculation,
    required int totalAyahs,
    required int totalPages,
  }) {
    if (request.calculationMethod ==
        MemorizationCalculationMethod.finishByDuration) {
      return _safeTargetDays(request.targetDays);
    }

    if (totalPages > 0 && dailyLoad.dailyPages > 0) {
      return math.max(1, (totalPages / dailyLoad.dailyPages).ceil());
    }

    return 30;
  }

  double _calculateBaseReviewPages({
    required MemorizationPlanRequest request,
    required int totalPages,
    required int reviewTotalPages,
    required int totalDays,
    required _PlanDailyLoad dailyLoad,
  }) {
    if (request.actionType == MemorizationActionType.newMemorization) {
      return 0.5;
    }

    if (request.actionType == MemorizationActionType.newWithReview) {
      if (request.reviewFromLearnedOnly) {
        return _clampReviewPages(dailyLoad.dailyPages, min: 0.5, max: 3);
      }

      final customDailyPages = request.safeReviewDailyPages;
      if (customDailyPages != null) {
        return _clampReviewPages(customDailyPages, min: 0.25, max: 10);
      }

      final reviewSessions =
          request.safeReviewTargetDays ?? math.max(1, totalDays);
      final pages = reviewTotalPages > 0
          ? reviewTotalPages / math.max(1, reviewSessions)
          : dailyLoad.dailyPages;

      return _clampReviewPages(_roundToHalfPage(pages), min: 0.5, max: 20);
    }

    if (request.actionType == MemorizationActionType.reviewOnly ||
        request.actionType == MemorizationActionType.strengthenAndTest) {
      if (request.calculationMethod ==
              MemorizationCalculationMethod.dailyAmount &&
          request.dailyPages != null) {
        return _clampReviewPages(request.dailyPages!, min: 0.5, max: 20);
      }

      final pages = totalPages > 0
          ? totalPages / math.max(1, totalDays)
          : dailyLoad.dailyPages;
      return _clampReviewPages(_roundToHalfPage(pages), min: 0.5, max: 20);
    }

    return 0.5;
  }

  int _reviewTotalPages(MemorizationPlanRequest request, int fallbackPages) {
    if (!request.includesScheduledReview) return fallbackPages;
    if (request.reviewFromLearnedOnly || request.reviewScope == null) {
      return math.max(1, fallbackPages);
    }

    switch (request.reviewScope!.type) {
      case MemorizationScopeType.juz:
        return 20;
      case MemorizationScopeType.hizb:
        return 10;
      case MemorizationScopeType.wholeQuran:
      case MemorizationScopeType.knownMemorized:
        return 604;
      case MemorizationScopeType.pages:
      case MemorizationScopeType.surah:
      case MemorizationScopeType.ayahs:
      case MemorizationScopeType.weakSpots:
        return math.max(1, request.reviewScope!.totalPages);
    }
  }

  int _effectiveReviewCalendarDays({
    required MemorizationPlanRequest request,
    required int reviewTotalPages,
    required double baseReviewPages,
  }) {
    if (!request.includesScheduledReview) return 0;

    if (request.actionType == MemorizationActionType.newWithReview &&
        request.reviewFromLearnedOnly) {
      return _safeTargetDays(request.targetDays);
    }

    final int every = _reviewIntervalForPreview(
      request: request,
      totalDays: _safeTargetDays(request.targetDays),
    );
    int sessions = request.safeReviewTargetDays ?? 0;

    if (sessions <= 0) {
      sessions = math.max(
        1,
        (reviewTotalPages / math.max(0.25, baseReviewPages)).ceil(),
      );
    }

    return 1 + ((sessions - 1) * every);
  }

  int _extraReviewDaysForSeparateCalendar({
    required MemorizationPlanRequest request,
    required int newMemorizationDays,
    required int reviewCalendarDays,
    required int reviewTotalPages,
    required double baseReviewPages,
  }) {
    if (!request.includesScheduledReview) return 0;

    // في خطط المراجعة فقط لا توجد أيام حفظ جديدة، لذلك لا نضيف أيامًا فوق المراجعة.
    if (!request.includesNewMemorization) return 0;

    // حفظ + مراجعة: لا نحشر المراجعة في نفس يوم الحفظ.
    // نضيف أيام مراجعة منفصلة حتى تكون المدة المعروضة صادقة.
    if (request.reviewFromLearnedOnly) {
      return _autoLearnedReviewSessions(newMemorizationDays);
    }

    int sessions = request.safeReviewTargetDays ?? 0;
    if (sessions <= 0) {
      sessions = math.max(
        1,
        (reviewTotalPages / math.max(0.25, baseReviewPages)).ceil(),
      );
    }

    return (sessions + 1).clamp(0, 999).toInt();
  }

  int _autoLearnedReviewSessions(int newMemorizationDays) {
    if (newMemorizationDays <= 3) return 1;

    final closeReviews = (newMemorizationDays / 4).floor();
    final widerReviews = (newMemorizationDays / 14).floor();

    // نضيف مراجعة شاملة ختامية كجزء مستقل من الرحلة.
    return math.max(1, closeReviews + widerReviews + 1);
  }

  double _suggestDailyPages(
    MemorizationUserType userType,
    int totalPages, {
    required bool review,
    required bool newMem,
  }) {
    if (totalPages <= 0) return 0.5;

    if (review && !newMem) {
      switch (userType) {
        case MemorizationUserType.beginner:
          return 1;
        case MemorizationUserType.returning:
          if (totalPages <= 10) return 1;
          if (totalPages <= 30) return 1.5;
          if (totalPages <= 100) return 2;
          if (totalPages <= 300) return 3;
          return 4;
        case MemorizationUserType.strong:
          if (totalPages >= 604) return 12;
          if (totalPages >= 300) return 8;
          if (totalPages >= 100) return 6;
          if (totalPages >= 30) return 4;
          if (totalPages >= 10) return 3;
          return 2;
      }
    }

    switch (userType) {
      case MemorizationUserType.beginner:
        if (totalPages <= 3) return 0.5;
        return 1;
      case MemorizationUserType.returning:
        return 1;
      case MemorizationUserType.strong:
        return 2;
    }
  }

  String _pathTitle(MemorizationPlanRequest request) {
    switch (request.actionType) {
      case MemorizationActionType.newMemorization:
        return 'مسار الحفظ الجديد';
      case MemorizationActionType.reviewOnly:
        return 'مسار المراجعة اليومية';
      case MemorizationActionType.newWithReview:
        return 'مسار حفظ ومراجعة متوازن';
      case MemorizationActionType.strengthenAndTest:
        return 'مسار الاختبار والتقوية';
    }
  }

  String _dailyNewText({
    required bool preferAyahCalculation,
    required int dailyAyahs,
    required double dailyPages,
    required int totalAyahs,
    required int totalPages,
  }) {
    final approxAyahs = _ayahsFromPages(
      totalAyahs: totalAyahs,
      totalPages: totalPages,
      pages: dailyPages,
    );

    if (approxAyahs > 0) {
      return '${_formatPages(dailyPages)} في كل جلسة حفظ، حوالي $approxAyahs آية';
    }

    return '${_formatPages(dailyPages)} في كل جلسة حفظ';
  }

  String _dailyReviewText({
    required MemorizationPlanRequest request,
    required double baseReviewPages,
    required int reviewTotalPages,
  }) {
    final every = _reviewIntervalForPreview(
      request: request,
      totalDays: _safeTargetDays(request.targetDays),
    );
    final everyText = request.usesSmartReviewDistribution
        ? 'بتوزيع ذكي'
        : every == 1
        ? 'بعد كل جلسة أساسية'
        : 'بعد كل $every جلسات أساسية';

    if (request.actionType == MemorizationActionType.newMemorization) {
      return 'مراجعة يسيرة لآخر ما تم حفظه';
    }

    if (request.actionType == MemorizationActionType.newWithReview) {
      if (request.reviewFromLearnedOnly) {
        return request.usesSmartReviewDistribution
            ? 'توزيع ذكي لمراجعة آخر ما تحفظه، مع مراجعة شاملة كل فترة.'
            : 'مراجعة من آخر ما تحفظه بعد كل ${request.safeReviewEveryDays} جلسات حفظ، مع مراجعة شاملة كل فترة.';
      }

      final sessions = math.max(
        1,
        (reviewTotalPages / math.max(0.25, baseReviewPages)).ceil(),
      );
      final effectiveDays = 1 + ((sessions - 1) * every);
      final reviewTitle = request.reviewScope?.rangeText ?? 'محفوظ سابق';
      return 'مراجعة $everyText من $reviewTitle: ${_formatPages(baseReviewPages)} في الجلسة، وتكتمل خلال $effectiveDays يوم تقريبًا.';
    }

    if (request.actionType == MemorizationActionType.reviewOnly) {
      return 'ورد مراجعة ثابت: ${_formatPages(baseReviewPages)} يوميًا';
    }

    return 'مراجعة وتقوية حسب حجم النطاق.';
  }

  String _selfTestText({required int totalDays, required bool includeTests}) {
    if (!includeTests) {
      return 'لن تُضاف اختبارات تلقائية لهذه الخطة';
    }
    if (totalDays <= 10) {
      return 'مراجعة منتصف الخطة واختبار ختامي موزعان تلقائيًا';
    }
    if (totalDays < 30) {
      return 'اختبارات مرحلية وختامية يوزعها النظام حسب تقدمك';
    }
    return 'اختبارات أسبوعية وشهرية وختامية يوزعها النظام تلقائيًا';
  }

  int _expectedTestsCount({
    required MemorizationPlanRequest request,
    required int totalDays,
    required int totalPages,
  }) {
    if (!request.includesPlannedTests) return 0;

    if (totalPages >= 580) {
      if (totalDays <= 10) return 2;
      if (totalDays <= 20) return 3;
    }

    if (request.actionType == MemorizationActionType.strengthenAndTest) {
      return _strongCadenceTestsCount(totalDays) + 1;
    }

    if (totalDays < 5) return 1;
    if (totalDays < 20) return 2;

    final weekly = (totalDays / 7).floor();
    final monthly = (totalDays / 30).floor();
    return math.max(1, weekly + monthly + 1);
  }

  int _strongCadenceTestsCount(int totalDays) {
    if (totalDays <= 3) return 0;
    int count = 0;
    int dayOffset = 2;
    bool addThreeDays = true;

    while (dayOffset < totalDays - 1) {
      count++;
      dayOffset += addThreeDays ? 3 : 2;
      addThreeDays = !addThreeDays;
    }

    return count;
  }

  String _loadText({required double newPages, required double reviewPages}) {
    final total = newPages + reviewPages;
    if (total <= 1.5) return 'مريح';
    if (total <= 3) return 'متوازن';
    if (total <= 5) return 'قوي';
    return 'قوي جدًا';
  }

  List<String> _systemPoints(MemorizationPlanRequest request) {
    final points = <String>[];

    if (request.includesNewMemorization) {
      points.add('الحفظ موزع على جلسات قصيرة قدر الإمكان.');
    }

    if (request.includesScheduledReview) {
      points.add(
        request.usesSmartReviewDistribution
            ? 'المراجعة موزعة تلقائيًا حسب حجم الرحلة.'
            : 'المراجعة تظهر بعد عدد الجلسات الذي اخترته.',
      );
    }

    points.add(
      'النظام يوزع الاختبارات تلقائيًا حسب مدة الخطة وتقدمك، ويخصص يوم الاختبار بلا حفظ جديد.',
    );

    if (request.safeWeeklyRestDays > 0) {
      points.add('أيام الراحة موزعة تلقائيًا بدون أيام متتالية.');
    }

    return points;
  }

  int _reviewIntervalForPreview({
    required MemorizationPlanRequest request,
    required int totalDays,
  }) {
    if (!request.usesSmartReviewDistribution) {
      return request.safeReviewEveryDays;
    }

    final days = totalDays <= 0 ? 30 : totalDays;

    if (request.reviewFromLearnedOnly) {
      if (days <= 10) return 2;
      if (days <= 30) return 3;
      return 4;
    }

    final sessions = request.safeReviewTargetDays;
    if (sessions != null && sessions > 0) {
      return (days / (sessions + 1)).floor().clamp(1, 6).toInt();
    }

    if (days <= 20) return 2;
    if (days <= 60) return 3;
    return 4;
  }

  int _safeTargetDays(int? days) {
    return (days ?? 30).clamp(1, 3650).toInt();
  }

  double _pagesFromAyahs({
    required int totalAyahs,
    required int totalPages,
    required int dailyAyahs,
  }) {
    if (totalAyahs <= 0 || totalPages <= 0) return 0.5;
    final double pages = (dailyAyahs / totalAyahs) * totalPages;
    return _roundToHalfPage(math.max(0.5, pages));
  }

  double _roundToHalfPage(double value) {
    if (value <= 0) return 0.5;
    return (value * 2).ceil() / 2;
  }

  double _clampReviewPages(
    double value, {
    required double min,
    required double max,
  }) {
    return value.clamp(min, max).toDouble();
  }

  int _ayahsFromPages({
    required int totalAyahs,
    required int totalPages,
    required double pages,
  }) {
    if (totalAyahs <= 0 || totalPages <= 0 || pages <= 0) return 0;
    return math.max(1, ((totalAyahs / totalPages) * pages).round());
  }

  String _formatPages(double value) {
    if (value == 0.5) return 'نصف صفحة';
    if (value == 1) return 'صفحة واحدة';
    if (value == 2) return 'صفحتين';
    if (value == value.roundToDouble()) {
      final int pages = value.toInt();
      if (pages >= 3 && pages <= 10) return '$pages صفحات';
      return '$pages صفحة';
    }
    return '${value.toStringAsFixed(1)} صفحة';
  }
}

class _PlanDailyLoad {
  final int dailyAyahs;
  final double dailyPages;

  const _PlanDailyLoad({required this.dailyAyahs, required this.dailyPages});
}
