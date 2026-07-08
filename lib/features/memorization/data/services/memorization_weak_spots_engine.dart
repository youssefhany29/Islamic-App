import '../../../quran/reader/quran_reader_helpers.dart';
import '../models/memorization_active_plan_model.dart';
import '../models/memorization_session_result_model.dart';
import '../models/memorization_today_task_model.dart';
import 'memorization_plan_storage.dart';
import 'memorization_session_result_storage.dart';

class MemorizationWeakSpotModel {
  final String key;
  final int startGlobalAyahIndex;
  final int endGlobalAyahIndex;
  final String scopeTitle;
  final String latestRating;
  final int attemptsCount;
  final int rescueSessionsCount;
  final int ayahsCount;
  final DateTime lastSeenAt;
  final MemorizationSessionResultModel latestResult;

  const MemorizationWeakSpotModel({
    required this.key,
    required this.startGlobalAyahIndex,
    required this.endGlobalAyahIndex,
    required this.scopeTitle,
    required this.latestRating,
    required this.attemptsCount,
    required this.rescueSessionsCount,
    required this.ayahsCount,
    required this.lastSeenAt,
    required this.latestResult,
  });

  bool get isForgotten => latestRating == 'forgot';

  String get ratingTitle {
    switch (latestRating) {
      case 'forgot':
        return 'منسي';
      case 'hard':
        return 'صعب';
      case 'good':
        return 'جيد';
      case 'easy':
        return 'سهل';
      default:
        return 'ضعيف';
    }
  }

  String get shortReason {
    if (latestRating == 'forgot') {
      return 'آخر تقييم كان نسيان، يحتاج إنقاذ قريب.';
    }

    return 'آخر تقييم كان صعب، يحتاج تثبيت هادئ.';
  }
}

class MemorizationWeakSpotsEngine {
  const MemorizationWeakSpotsEngine();

  Future<List<MemorizationWeakSpotModel>> getWeakSpots({
    bool activePlanOnly = true,
  }) async {
    final results = await MemorizationSessionResultStorage.getResults();
    final activePlan = await MemorizationPlanStorage.getActivePlan();

    return buildWeakSpots(
      results: results,
      activePlan: activePlan,
      activePlanOnly: activePlanOnly,
    );
  }

  List<MemorizationWeakSpotModel> buildWeakSpots({
    required List<MemorizationSessionResultModel> results,
    MemorizationActivePlanModel? activePlan,
    bool activePlanOnly = true,
  }) {
    final filtered = results.where((result) {
      if (result.taskType == 'selfTest') return false;

      if (activePlanOnly && activePlan != null) {
        final overlapsActivePlan = result.endGlobalAyahIndex >=
            activePlan.scopeStartGlobalAyahIndex &&
            result.startGlobalAyahIndex <= activePlan.scopeEndGlobalAyahIndex;

        if (!overlapsActivePlan) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final grouped = <String, List<MemorizationSessionResultModel>>{};

    for (final result in filtered) {
      final key = _rangeKey(
        startGlobalAyahIndex: result.startGlobalAyahIndex,
        endGlobalAyahIndex: result.endGlobalAyahIndex,
      );

      grouped.putIfAbsent(key, () => <MemorizationSessionResultModel>[]).add(
        result,
      );
    }

    final weakSpots = <MemorizationWeakSpotModel>[];

    grouped.forEach((key, group) {
      group.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      final latest = group.first;
      final latestIsWeak = latest.rating == 'hard' || latest.rating == 'forgot';

      // لو آخر تقييم لنفس الموضع أصبح جيد/سهل، لا نعتبره موضعًا ضعيفًا الآن.
      if (!latestIsWeak) return;

      final rescueSessionsCount = group.where((result) {
        return result.taskType == 'weakReview';
      }).length;

      weakSpots.add(
        MemorizationWeakSpotModel(
          key: key,
          startGlobalAyahIndex: latest.startGlobalAyahIndex,
          endGlobalAyahIndex: latest.endGlobalAyahIndex,
          scopeTitle: _rangeTitle(
            latest.startGlobalAyahIndex,
            latest.endGlobalAyahIndex,
          ),
          latestRating: latest.rating,
          attemptsCount: group.length,
          rescueSessionsCount: rescueSessionsCount,
          ayahsCount: latest.ayahsCount,
          lastSeenAt: latest.completedAt,
          latestResult: latest,
        ),
      );
    });

    weakSpots.sort((a, b) {
      final ratingPriorityA = a.latestRating == 'forgot' ? 0 : 1;
      final ratingPriorityB = b.latestRating == 'forgot' ? 0 : 1;
      final ratingCompare = ratingPriorityA.compareTo(ratingPriorityB);
      if (ratingCompare != 0) return ratingCompare;

      return b.lastSeenAt.compareTo(a.lastSeenAt);
    });

    return weakSpots;
  }

  MemorizationTodayTaskModel buildRescueTaskFromWeakSpot(
      MemorizationWeakSpotModel weakSpot,
      ) {
    final now = DateTime.now();

    return MemorizationTodayTaskModel(
      id: 'weak_spot_rescue_${weakSpot.key}_${now.microsecondsSinceEpoch}',
      planId: 'weak_spot_${weakSpot.key}',
      type: 'weakReview',
      title: 'جلسة إنقاذ موضع ضعيف',
      subtitle: weakSpot.isForgotten
          ? 'مقطع منسي يحتاج تثبيتًا هادئًا.'
          : 'مقطع صعب يحتاج مراجعة مركزة.',
      scopeTitle: weakSpot.scopeTitle,
      startGlobalAyahIndex: weakSpot.startGlobalAyahIndex,
      endGlobalAyahIndex: weakSpot.endGlobalAyahIndex,
      expectedMinutes: _estimateMinutes(weakSpot.ayahsCount),
      isCompleted: false,
      status: MemorizationTodayTaskModel.statusNotStarted,
      scheduledDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  int _estimateMinutes(int ayahsCount) {
    final safeAyahs = ayahsCount.clamp(1, 80);
    final minutes = 6 + (safeAyahs * 0.75);
    return minutes.clamp(8, 35).round();
  }

  String _rangeKey({
    required int startGlobalAyahIndex,
    required int endGlobalAyahIndex,
  }) {
    return '${startGlobalAyahIndex}_$endGlobalAyahIndex';
  }

  String _rangeTitle(int startGlobalAyahIndex, int endGlobalAyahIndex) {
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
}
