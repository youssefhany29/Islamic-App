import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_database_service.dart';

enum DataMigrationDomain {
  quran,
  prayer,
  memorization,
  recitation,
  azkar,
  hadith,
}

class DataMigrationSummary {
  final bool globalMigrationCompleted;
  final Map<DataMigrationDomain, bool> completedDomains;
  final Map<String, int> migratedRecordCounts;

  const DataMigrationSummary({
    required this.globalMigrationCompleted,
    required this.completedDomains,
    required this.migratedRecordCounts,
  });
}

class DataMigrationService {
  DataMigrationService({
    LocalDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? LocalDatabaseService.instance;

  static const String globalCompletedKey = 'drift_migration_v1_completed';
  static const String globalStartedAtKey = 'drift_migration_v1_started_at';
  static const String globalCompletedAtKey = 'drift_migration_v1_completed_at';

  static const Map<DataMigrationDomain, String> domainCompletedKeys = {
    DataMigrationDomain.quran: 'drift_migration_quran_v1_completed',
    DataMigrationDomain.prayer: 'drift_migration_prayer_v1_completed',
    DataMigrationDomain.memorization:
        'drift_migration_memorization_v1_completed',
    DataMigrationDomain.recitation: 'drift_migration_recitation_v1_completed',
    DataMigrationDomain.azkar: 'drift_migration_azkar_v1_completed',
    DataMigrationDomain.hadith: 'drift_migration_hadith_v1_completed',
  };

  final LocalDatabaseService _databaseService;

  Future<void> ensureDatabaseReady() async {
    try {
      await _databaseService.database.ensureOpen();
    } catch (error, stackTrace) {
      debugPrint('Drift database open failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> runPendingMigrations() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(globalCompletedKey) == true) {
      return;
    }

    await prefs.setString(
      globalStartedAtKey,
      DateTime.now().toIso8601String(),
    );

    try {
      await ensureDatabaseReady();

      // Important: Phase 1 only creates the database foundation. Domain data is
      // migrated in later small steps so existing SharedPreferences reads remain
      // the source of truth until each repository is safely switched over.
      await markGlobalMigrationCompletedIfAllDomainsCompleted();
    } catch (error, stackTrace) {
      debugPrint('Drift migration v1 failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> markGlobalMigrationCompletedIfAllDomainsCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in domainCompletedKeys.values) {
      if (prefs.getBool(key) != true) {
        return;
      }
    }

    await prefs.setBool(globalCompletedKey, true);
    await prefs.setString(
      globalCompletedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> markDomainMigrationCompleted(DataMigrationDomain domain) async {
    final key = domainCompletedKeys[domain];
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    await markGlobalMigrationCompletedIfAllDomainsCompleted();
  }

  Future<bool> isDomainMigrationCompleted(DataMigrationDomain domain) async {
    final key = domainCompletedKeys[domain];
    if (key == null) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<DataMigrationSummary> debugBuildMigrationSummary() async {
    final prefs = await SharedPreferences.getInstance();

    final completedDomains = <DataMigrationDomain, bool>{};
    for (final domain in DataMigrationDomain.values) {
      completedDomains[domain] = await isDomainMigrationCompleted(domain);
    }

    final counts = <String, int>{};

    if (kDebugMode) {
      const tableNames = [
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
      ];

      for (final tableName in tableNames) {
        try {
          counts[tableName] =
              await _databaseService.localDataDao.countTable(tableName);
        } catch (error) {
          debugPrint('Could not count $tableName during migration summary: $error');
        }
      }
    }

    return DataMigrationSummary(
      globalMigrationCompleted: prefs.getBool(globalCompletedKey) ?? false,
      completedDomains: completedDomains,
      migratedRecordCounts: counts,
    );
  }
}
