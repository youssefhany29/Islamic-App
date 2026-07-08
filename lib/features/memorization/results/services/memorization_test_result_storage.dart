import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memorization_test_result_model.dart';

class MemorizationTestResultStorage {
  static const String _storageKey = 'memorization_test_results_v1';
  static const int _maxResults = 500;

  const MemorizationTestResultStorage();

  Future<List<MemorizationTestResultModel>> getResults({String? planId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final results =
          decoded
              .whereType<Map>()
              .map(
                (item) => MemorizationTestResultModel.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => planId == null || item.planId == planId)
              .toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<void> addResult(MemorizationTestResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = (await getResults()).toList(growable: true);
    results.removeWhere((item) => item.id == result.id);
    results.insert(0, result);
    await prefs.setString(
      _storageKey,
      jsonEncode(
        results.take(_maxResults).map((item) => item.toMap()).toList(),
      ),
    );
  }
}
