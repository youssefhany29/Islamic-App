import 'memorization_action_type.dart';
import 'memorization_calculation_method.dart';
import 'memorization_goal_option.dart';
import 'memorization_scope_selection.dart';
import 'memorization_test_preferences.dart';
import 'memorization_user_type.dart';

class MemorizationPlanRequest {
  final MemorizationUserType userType;
  final MemorizationActionType actionType;
  final MemorizationScopeSelection scope;
  final MemorizationCalculationMethod calculationMethod;

  /// نطاق مراجعة مستقل عن نطاق الحفظ.
  /// يستخدم خصوصًا في حفظ + مراجعة لمن يحفظ شيئًا ويراجع شيئًا آخر.
  final MemorizationScopeSelection? reviewScope;

  /// لو true: المراجعة تكون من الذي تم حفظه داخل نفس الخطة فقط.
  /// مناسب للمبتدئ؛ لا نطلب منه اختيار محفوظ سابق.
  final bool reviewFromLearnedOnly;

  /// لو true: التطبيق يختار وتيرة المراجعة تلقائيًا حسب حجم الخطة.
  final bool smartReviewDistribution;

  /// بعد كل كام جلسة أساسية تظهر المراجعة عند اختيار التوزيع اليدوي.
  final int reviewEveryDays;

  /// عدد جلسات المراجعة المطلوبة لإنهاء نطاق المراجعة.
  /// مثال: 5 يعني خمس جلسات مراجعة، ثم يتم توزيعها حسب reviewEveryDays.
  final int? reviewTargetDays;

  /// مقدار مراجعة الصفحات في كل جلسة مراجعة.
  final double? reviewDailyPages;

  /// Legacy compatibility only. The schedule planner now decides the real
  /// number of tests automatically and the user never edits this value.
  final int plannedTestsCount;

  /// Whether the user wants automatic tests included in this plan.
  /// The planner still owns their count and dates.
  final bool includeTests;

  /// User preferences affect the shape of every test, never its frequency.
  final MemorizationTestPreferences testPreferences;

  /// عدد أيام الراحة في الأسبوع.
  /// لا يحدد أيامًا بعينها؛ المحرك يوزعها تلقائيًا بدون أيام متتالية.
  final int weeklyRestDays;

  /// dailyAyahs باقٍ للتوافق مع نسخ قديمة فقط.
  /// لا يعتمد عليه منطق الخطة الحالي بعد إزالة اختيار مقدار الآيات من الواجهة.
  final int? dailyAyahs;

  /// لو المستخدم اختار مقدار صفحات لكل جلسة.
  final double? dailyPages;

  /// لو المستخدم اختار مدة/عدد أيام.
  final int? targetDays;

  /// محفوظ مؤقتًا لو لسه فيه صفحات قديمة بتستخدم MemorizationGoalOption.
  final MemorizationGoalOption? legacyGoal;

  const MemorizationPlanRequest({
    required this.userType,
    required this.actionType,
    required this.scope,
    required this.calculationMethod,
    this.reviewScope,
    this.reviewFromLearnedOnly = true,
    this.smartReviewDistribution = true,
    this.reviewEveryDays = 1,
    this.reviewTargetDays,
    this.reviewDailyPages,
    this.plannedTestsCount = 0,
    this.includeTests = true,
    this.testPreferences = const MemorizationTestPreferences(),
    this.weeklyRestDays = 0,
    this.dailyAyahs,
    this.dailyPages,
    this.targetDays,
    this.legacyGoal,
  });

  MemorizationPlanRequest copyWith({
    MemorizationUserType? userType,
    MemorizationActionType? actionType,
    MemorizationScopeSelection? scope,
    MemorizationCalculationMethod? calculationMethod,
    MemorizationScopeSelection? reviewScope,
    bool? reviewFromLearnedOnly,
    bool? smartReviewDistribution,
    int? reviewEveryDays,
    int? reviewTargetDays,
    bool clearReviewTargetDays = false,
    double? reviewDailyPages,
    bool clearReviewDailyPages = false,
    int? plannedTestsCount,
    bool? includeTests,
    MemorizationTestPreferences? testPreferences,
    int? weeklyRestDays,
    int? dailyAyahs,
    bool clearDailyAyahs = false,
    double? dailyPages,
    bool clearDailyPages = false,
    int? targetDays,
    bool clearTargetDays = false,
    MemorizationGoalOption? legacyGoal,
    bool clearLegacyGoal = false,
  }) {
    return MemorizationPlanRequest(
      userType: userType ?? this.userType,
      actionType: actionType ?? this.actionType,
      scope: scope ?? this.scope,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      reviewScope: reviewScope ?? this.reviewScope,
      reviewFromLearnedOnly:
          reviewFromLearnedOnly ?? this.reviewFromLearnedOnly,
      smartReviewDistribution:
          smartReviewDistribution ?? this.smartReviewDistribution,
      reviewEveryDays: reviewEveryDays ?? this.reviewEveryDays,
      reviewTargetDays: clearReviewTargetDays
          ? null
          : reviewTargetDays ?? this.reviewTargetDays,
      reviewDailyPages: clearReviewDailyPages
          ? null
          : reviewDailyPages ?? this.reviewDailyPages,
      plannedTestsCount: plannedTestsCount ?? this.plannedTestsCount,
      includeTests: includeTests ?? this.includeTests,
      testPreferences: testPreferences ?? this.testPreferences,
      weeklyRestDays: (weeklyRestDays ?? this.weeklyRestDays)
          .clamp(0, 3)
          .toInt(),
      dailyAyahs: clearDailyAyahs ? null : dailyAyahs ?? this.dailyAyahs,
      dailyPages: clearDailyPages ? null : dailyPages ?? this.dailyPages,
      targetDays: clearTargetDays ? null : targetDays ?? this.targetDays,
      legacyGoal: clearLegacyGoal ? null : legacyGoal ?? this.legacyGoal,
    );
  }

  bool get isReviewPlan {
    return actionType == MemorizationActionType.reviewOnly ||
        actionType == MemorizationActionType.strengthenAndTest;
  }

  bool get includesNewMemorization {
    return actionType == MemorizationActionType.newMemorization ||
        actionType == MemorizationActionType.newWithReview;
  }

  bool get includesScheduledReview {
    return actionType == MemorizationActionType.newWithReview ||
        actionType == MemorizationActionType.reviewOnly ||
        actionType == MemorizationActionType.strengthenAndTest;
  }

  bool get includesPlannedTests {
    return includeTests;
  }

  int get safeReviewEveryDays {
    return reviewEveryDays.clamp(1, 7).toInt();
  }

  bool get usesSmartReviewDistribution {
    return smartReviewDistribution;
  }

  int get safeWeeklyRestDays {
    return weeklyRestDays.clamp(0, 3).toInt();
  }

  int? get safeReviewTargetDays {
    final value = reviewTargetDays;
    if (value == null || value <= 0) return null;
    return value.clamp(1, 999).toInt();
  }

  double? get safeReviewDailyPages {
    final value = reviewDailyPages;
    if (value == null || value <= 0) return null;
    return value.clamp(0.25, 30).toDouble();
  }
}
