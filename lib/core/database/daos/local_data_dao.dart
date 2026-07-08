import '../app_database.dart';

class LocalDataDao {
  LocalDataDao(this.db);

  final AppDatabase db;

  Future<void> upsert(String tableName, Map<String, Object?> values) async {
    _checkKnownTable(tableName);
    if (values.isEmpty) return;

    final columns = values.keys.toList();
    final placeholders = List<String>.filled(columns.length, '?').join(', ');
    final columnSql = columns.map(_toSnakeCase).join(', ');

    await db.runInsert(
      'INSERT OR REPLACE INTO $tableName ($columnSql) VALUES ($placeholders)',
      values.values.toList(),
    );
  }

  Future<void> upsertFavorite(Map<String, Object?> values) {
    return upsert('favorite_entries', values);
  }

  Future<void> upsertQuranProgress(Map<String, Object?> values) {
    return upsert('quran_progress_entries', values);
  }

  Future<void> upsertQuranBookmark(Map<String, Object?> values) {
    return upsert('quran_bookmark_entries', values);
  }

  Future<void> upsertQuranWirdPlan(Map<String, Object?> values) {
    return upsert('quran_wird_plan_entries', values);
  }

  Future<void> upsertQuranWirdProgress(Map<String, Object?> values) {
    return upsert('quran_wird_progress_entries', values);
  }

  Future<void> upsertPrayerTrackingDay(Map<String, Object?> values) {
    return upsert('prayer_tracking_days', values);
  }

  Future<void> upsertPrayerTrackingStats(Map<String, Object?> values) {
    return upsert('prayer_tracking_stats', values);
  }

  Future<void> upsertNightPrayerTrackingDay(Map<String, Object?> values) {
    return upsert('night_prayer_tracking_days', values);
  }

  Future<void> upsertRawatibTrackingDay(Map<String, Object?> values) {
    return upsert('rawatib_tracking_days', values);
  }

  Future<void> upsertMemorizationPlan(Map<String, Object?> values) {
    return upsert('memorization_plan_entries', values);
  }

  Future<void> upsertMemorizationTask(Map<String, Object?> values) {
    return upsert('memorization_task_entries', values);
  }

  Future<void> upsertMemorizationProgress(Map<String, Object?> values) {
    return upsert('memorization_progress_entries', values);
  }

  Future<void> upsertMemorizationSessionResult(Map<String, Object?> values) {
    return upsert('memorization_session_result_entries', values);
  }

  Future<void> upsertRecitationProgress(Map<String, Object?> values) {
    return upsert('recitation_progress_entries', values);
  }

  Future<void> upsertRecitationHistory(Map<String, Object?> values) {
    return upsert('recitation_history_entries', values);
  }

  Future<void> upsertRecitationStats(Map<String, Object?> values) {
    return upsert('recitation_stats_entries', values);
  }

  Future<void> upsertRecitationFavorite(Map<String, Object?> values) {
    return upsert('recitation_favorite_entries', values);
  }

  Future<void> upsertRecitationDownload(Map<String, Object?> values) {
    return upsert('recitation_download_entries', values);
  }

  Future<void> upsertRecitationCustomGoal(Map<String, Object?> values) {
    return upsert('recitation_custom_goal_entries', values);
  }

  Future<void> upsertDailyContentProgress(Map<String, Object?> values) {
    return upsert('daily_content_progress_entries', values);
  }

  Future<void> upsertMemoryAttempt(Map<String, Object?> values) {
    return upsert('memory_attempt_entries', values);
  }

  Future<void> upsertCustomContent(Map<String, Object?> values) {
    return upsert('custom_content_entries', values);
  }

  Future<void> upsertAchievement(Map<String, Object?> values) {
    return upsert('achievement_entries', values);
  }

  Future<void> upsertAppCache(Map<String, Object?> values) {
    return upsert('app_cache_entries', values);
  }

  Future<int> countTable(String tableName) async {
    _checkKnownTable(tableName);

    final rows = await db.runSelect('SELECT COUNT(*) AS count FROM $tableName');
    if (rows.isEmpty) return 0;

    final count = rows.first['count'];
    return count is int ? count : int.tryParse(count.toString()) ?? 0;
  }

  void _checkKnownTable(String tableName) {
    if (!_knownTables.contains(tableName)) {
      throw ArgumentError.value(tableName, 'tableName', 'Unknown local table');
    }
  }

  String _toSnakeCase(String value) {
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final lower = char.toLowerCase();
      final isUpper = char != lower;

      if (isUpper && i > 0) {
        buffer.write('_');
      }

      buffer.write(lower);
    }

    return buffer.toString();
  }
}

const Set<String> _knownTables = {
  'favorite_entries',
  'quran_progress_entries',
  'quran_bookmark_entries',
  'quran_wird_plan_entries',
  'quran_wird_progress_entries',
  'prayer_tracking_days',
  'prayer_tracking_stats',
  'night_prayer_tracking_days',
  'rawatib_tracking_days',
  'memorization_plan_entries',
  'memorization_task_entries',
  'memorization_progress_entries',
  'memorization_session_result_entries',
  'recitation_progress_entries',
  'recitation_history_entries',
  'recitation_stats_entries',
  'recitation_favorite_entries',
  'recitation_download_entries',
  'recitation_custom_goal_entries',
  'daily_content_progress_entries',
  'memory_attempt_entries',
  'custom_content_entries',
  'achievement_entries',
  'app_cache_entries',
};
