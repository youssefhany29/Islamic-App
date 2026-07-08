import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memorization_session_result_model.dart';

class MemorizationSessionResultStorage {
  static const String _resultsKey = 'my_lessons_memorization_session_results';

  const MemorizationSessionResultStorage._();

  static Future<List<MemorizationSessionResultModel>> getResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_resultsKey);

    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => MemorizationSessionResultModel.fromMap(
        Map<String, dynamic>.from(item),
      ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addResult(MemorizationSessionResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getResults();

    results.removeWhere((item) => item.taskId == result.taskId);
    results.insert(0, result);

    await prefs.setString(
      _resultsKey,
      jsonEncode(results.map((item) => item.toMap()).toList()),
    );
  }

  static Future<MemorizationSessionResultModel?> getResultByTaskId(
      String taskId,
      ) async {
    final results = await getResults();

    for (final result in results) {
      if (result.taskId == taskId) return result;
    }

    return null;
  }

  static Future<int> completedSessionsCount() async {
    final results = await getResults();
    return results.length;
  }

  static Future<int> completedAyahsCount() async {
    final results = await getResults();

    return results.fold<int>(
      0,
          (sum, result) => sum + result.ayahsCount,
    );
  }

  static Future<int> weakResultsCount() async {
    final results = await getResults();

    return results.where((result) => result.needsRescueReview).length;
  }

  static Future<void> clearResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resultsKey);
  }
}
