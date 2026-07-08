import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../main_quraan_components/constant.dart';
import '../reader/quran_page_mapper.dart';
import '../reader/quran_reader_helpers.dart';
import 'quran_wird_progress_storage.dart';

class QuranKhatmaPlan {
  final String id;
  final String name;
  final DateTime startDate;
  final int totalDays;
  final int completedDays;
  final bool isActive;
  final DateTime? completedAt;

  const QuranKhatmaPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.totalDays,
    required this.completedDays,
    required this.isActive,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'totalDays': totalDays,
      'completedDays': completedDays,
      'isActive': isActive,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory QuranKhatmaPlan.fromJson(Map<String, dynamic> json) {
    return QuranKhatmaPlan(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : 'ختمة بدون اسم',
      startDate:
          DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now(),
      totalDays: int.tryParse(json['totalDays'].toString()) ?? 30,
      completedDays: int.tryParse(json['completedDays'].toString()) ?? 0,
      isActive: json['isActive'] == true,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'].toString()),
    );
  }

  QuranKhatmaPlan copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    int? totalDays,
    int? completedDays,
    bool? isActive,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return QuranKhatmaPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalDays: totalDays ?? this.totalDays,
      completedDays: completedDays ?? this.completedDays,
      isActive: isActive ?? this.isActive,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }
}

class QuranDailyWird {
  final String planId;
  final String planName;
  final int dayNumber;
  final int fromGlobalAyahIndex;
  final int toGlobalAyahIndex;
  final int fromSuraIndex;
  final int fromAyahIndex;
  final int toSuraIndex;
  final int toAyahIndex;
  final int fromPageNumber;
  final int toPageNumber;
  final bool isCompleted;

  const QuranDailyWird({
    required this.planId,
    required this.planName,
    required this.dayNumber,
    required this.fromGlobalAyahIndex,
    required this.toGlobalAyahIndex,
    required this.fromSuraIndex,
    required this.fromAyahIndex,
    required this.toSuraIndex,
    required this.toAyahIndex,
    required this.fromPageNumber,
    required this.toPageNumber,
    required this.isCompleted,
  });
}

class QuranWirdStorage {
  static const String _activePlansKey = 'quran_active_khatma_plans';
  static const String _completedPlansKey = 'quran_completed_khatma_plans';

  /// Backward compatibility لو كان عندك الخطة القديمة المفردة.
  static const String _oldSinglePlanKey = 'quran_khatma_plan';

  static Future<List<QuranKhatmaPlan>> getActivePlans() async {
    await _migrateOldSinglePlanIfNeeded();

    final prefs = await SharedPreferences.getInstance();
    final rawPlans = prefs.getString(_activePlansKey);

    if (rawPlans == null || rawPlans.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawPlans) as List;

      return decoded
          .whereType<Map>()
          .map(
            (item) => QuranKhatmaPlan.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((plan) => plan.isActive)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<QuranKhatmaPlan>> getCompletedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPlans = prefs.getString(_completedPlansKey);

    if (rawPlans == null || rawPlans.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawPlans) as List;

      return decoded
          .whereType<Map>()
          .map(
            (item) => QuranKhatmaPlan.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveActivePlans(List<QuranKhatmaPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();

    final activePlans = plans.where((plan) => plan.isActive).toList();

    await prefs.setString(
      _activePlansKey,
      jsonEncode(activePlans.map((plan) => plan.toJson()).toList()),
    );
  }

  static Future<void> saveCompletedPlans(List<QuranKhatmaPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _completedPlansKey,
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }

  static Future<void> createKhatmaPlan({
    required String name,
    required int totalDays,
  }) async {
    final plans = await getActivePlans();

    final trimmedName = name.trim();

    final plan = QuranKhatmaPlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName.isEmpty ? 'ختمة جديدة' : trimmedName,
      startDate: DateTime.now(),
      totalDays: totalDays,
      completedDays: 0,
      isActive: true,
      completedAt: null,
    );

    plans.insert(0, plan);

    await saveActivePlans(plans);
  }

  static Future<void> deleteActivePlan(String planId) async {
    final plans = await getActivePlans();

    plans.removeWhere((plan) => plan.id == planId);

    await saveActivePlans(plans);
  }

  static Future<void> deleteCompletedPlan(String planId) async {
    final completedPlans = await getCompletedPlans();

    completedPlans.removeWhere((plan) => plan.id == planId);

    await saveCompletedPlans(completedPlans);
  }

  static Future<void> markPlanTodayWirdCompleted(String planId) async {
    final activePlans = await getActivePlans();
    final completedPlans = await getCompletedPlans();

    final index = activePlans.indexWhere((plan) => plan.id == planId);

    if (index == -1) return;

    await QuranWirdProgressStorage.markTodayCompleted(planId);

    final plan = activePlans[index];

    final nextCompletedDays = plan.completedDays + 1;

    final isFinished = nextCompletedDays >= plan.totalDays;

    final updatedPlan = plan.copyWith(
      completedDays: nextCompletedDays > plan.totalDays
          ? plan.totalDays
          : nextCompletedDays,
      isActive: !isFinished,
      completedAt: isFinished ? DateTime.now() : null,
    );

    activePlans.removeAt(index);

    if (isFinished) {
      completedPlans.insert(0, updatedPlan);
      await saveCompletedPlans(completedPlans);
    } else {
      activePlans.insert(index, updatedPlan);
    }

    await saveActivePlans(activePlans);
  }

  static Future<List<QuranDailyWird>> buildTodayWirds() async {
    final activePlans = await getActivePlans();

    final List<QuranDailyWird> wirds = [];

    for (final plan in activePlans) {
      final wird = await buildTodayWird(plan);
      wirds.add(wird);
    }

    return wirds;
  }

  static Future<QuranDailyWird> buildTodayWird(QuranKhatmaPlan plan) async {
    await QuranPageMapper.load();

    const int totalPages = QuranPageMapper.totalMushafPages;

    final safeTotalDays = plan.totalDays <= 0 ? 30 : plan.totalDays;
    final currentDay = plan.completedDays + 1;
    final safeCurrentDay = currentDay > safeTotalDays
        ? safeTotalDays
        : currentDay;

    final pagesPerDay = (totalPages / safeTotalDays).ceil();

    final fromPageNumber = (((safeCurrentDay - 1) * pagesPerDay) + 1).clamp(
      1,
      totalPages,
    );

    final toPageNumber = (fromPageNumber + pagesPerDay - 1).clamp(
      1,
      totalPages,
    );

    final fromGlobalAyahIndex = QuranPageMapper.getGlobalAyahIndexForPage(
      fromPageNumber,
    );

    final nextPage = (toPageNumber + 1).clamp(1, totalPages);

    int toGlobalAyahIndex;

    if (toPageNumber >= totalPages) {
      toGlobalAyahIndex = QuranReaderHelpers.totalAyahs - 1;
    } else {
      toGlobalAyahIndex =
          QuranPageMapper.getGlobalAyahIndexForPage(nextPage) - 1;
    }

    if (toGlobalAyahIndex < fromGlobalAyahIndex) {
      toGlobalAyahIndex = fromGlobalAyahIndex;
    }

    final fromPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      fromGlobalAyahIndex,
    );

    final toPosition = QuranReaderHelpers.getPositionFromGlobalIndex(
      toGlobalAyahIndex,
    );

    return QuranDailyWird(
      planId: plan.id,
      planName: plan.name,
      dayNumber: safeCurrentDay,
      fromGlobalAyahIndex: fromGlobalAyahIndex,
      toGlobalAyahIndex: toGlobalAyahIndex,
      fromSuraIndex: fromPosition.suraIndex,
      fromAyahIndex: fromPosition.ayahIndex,
      toSuraIndex: toPosition.suraIndex,
      toAyahIndex: toPosition.ayahIndex,
      fromPageNumber: fromPageNumber,
      toPageNumber: toPageNumber,
      isCompleted: plan.completedDays >= safeCurrentDay,
    );
  }

  static String getSuraName(int suraIndex) {
    return arabicName[suraIndex]['name'].toString();
  }

  static Future<void> _migrateOldSinglePlanIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    final oldRawPlan = prefs.getString(_oldSinglePlanKey);
    final newRawPlans = prefs.getString(_activePlansKey);

    if (oldRawPlan == null || oldRawPlan.trim().isEmpty) return;
    if (newRawPlans != null && newRawPlans.trim().isNotEmpty) return;

    try {
      final oldPlan =
          QuranKhatmaPlan.fromJson(
            Map<String, dynamic>.from(jsonDecode(oldRawPlan)),
          ).copyWith(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: 'ختمتي الأولى',
            isActive: true,
            clearCompletedAt: true,
          );

      await saveActivePlans([oldPlan]);
      await prefs.remove(_oldSinglePlanKey);
    } catch (_) {
      await prefs.remove(_oldSinglePlanKey);
    }
  }
}
