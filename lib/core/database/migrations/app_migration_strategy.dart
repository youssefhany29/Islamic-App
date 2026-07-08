import '../app_database.dart';

Future<void> createSchemaV1IfNeeded(AppDatabase database) async {
  // Important: Future schema changes must be additive and non-destructive.
  // Do not drop tables or clear data during upgrades; existing users rely on
  // local Quran, prayer, memorization, recitation, azkar, and hadith progress.
  //
  // When moving to schemaVersion 2, add a version table or Drift generated
  // migration and gate changes like:
  // if (from < 2) { ALTER TABLE ... ADD COLUMN ...; }
  for (final statement in _schemaV1Statements) {
    await database.runSchemaStatement(statement);
  }
}

const List<String> _schemaV1Statements = [
  '''
  CREATE TABLE IF NOT EXISTS favorite_entries (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    reference_id TEXT,
    title TEXT,
    subtitle TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS quran_progress_entries (
    id TEXT PRIMARY KEY,
    progress_type TEXT NOT NULL,
    surah_number INTEGER,
    ayah_number INTEGER,
    page_number INTEGER,
    juz_number INTEGER,
    plan_id TEXT,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS quran_bookmark_entries (
    id TEXT PRIMARY KEY,
    surah_number INTEGER,
    ayah_number INTEGER,
    page_number INTEGER,
    title TEXT,
    note TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS quran_wird_plan_entries (
    id TEXT PRIMARY KEY,
    title TEXT,
    start_date INTEGER,
    target_date INTEGER,
    status TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS quran_wird_progress_entries (
    id TEXT PRIMARY KEY,
    plan_id TEXT NOT NULL,
    surah_number INTEGER,
    ayah_number INTEGER,
    page_number INTEGER,
    completed_pages INTEGER,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS prayer_tracking_days (
    date TEXT PRIMARY KEY,
    fajr_done INTEGER NOT NULL DEFAULT 0,
    dhuhr_done INTEGER NOT NULL DEFAULT 0,
    asr_done INTEGER NOT NULL DEFAULT 0,
    maghrib_done INTEGER NOT NULL DEFAULT 0,
    isha_done INTEGER NOT NULL DEFAULT 0,
    completed_today INTEGER NOT NULL DEFAULT 0,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS prayer_tracking_stats (
    id TEXT PRIMARY KEY,
    current_streak INTEGER NOT NULL DEFAULT 0,
    best_streak INTEGER NOT NULL DEFAULT 0,
    last_date TEXT,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS night_prayer_tracking_days (
    date TEXT PRIMARY KEY,
    checked INTEGER NOT NULL DEFAULT 0,
    completed_today INTEGER NOT NULL DEFAULT 0,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS rawatib_tracking_days (
    date TEXT PRIMARY KEY,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS memorization_plan_entries (
    id TEXT PRIMARY KEY,
    title TEXT,
    status TEXT,
    active INTEGER NOT NULL DEFAULT 0,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS memorization_task_entries (
    id TEXT PRIMARY KEY,
    plan_id TEXT,
    task_date INTEGER,
    status TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS memorization_progress_entries (
    id TEXT PRIMARY KEY,
    task_id TEXT,
    plan_id TEXT,
    status TEXT,
    mistakes_count INTEGER,
    review_level INTEGER,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS memorization_session_result_entries (
    id TEXT PRIMARY KEY,
    plan_id TEXT,
    task_id TEXT,
    score INTEGER,
    mistakes_count INTEGER,
    payload_json TEXT,
    created_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recitation_progress_entries (
    id TEXT PRIMARY KEY,
    source TEXT,
    reciter_id INTEGER,
    surah_number INTEGER,
    position_seconds INTEGER NOT NULL DEFAULT 0,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    last_listened_at INTEGER,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recitation_history_entries (
    id TEXT PRIMARY KEY,
    source TEXT,
    reciter_id INTEGER,
    surah_number INTEGER,
    listened_seconds INTEGER NOT NULL DEFAULT 0,
    payload_json TEXT,
    created_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recitation_stats_entries (
    id TEXT PRIMARY KEY,
    total_seconds INTEGER NOT NULL DEFAULT 0,
    streak INTEGER NOT NULL DEFAULT 0,
    best_streak INTEGER NOT NULL DEFAULT 0,
    last_active_date TEXT,
    daily_goal_seconds INTEGER,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recitation_favorite_entries (
    id TEXT PRIMARY KEY,
    source TEXT,
    reciter_id INTEGER,
    surah_number INTEGER,
    title TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recitation_download_entries (
    id TEXT PRIMARY KEY,
    source TEXT,
    reciter_id INTEGER,
    surah_number INTEGER,
    file_path TEXT,
    audio_url TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS recitation_custom_goal_entries (
    id TEXT PRIMARY KEY,
    title TEXT,
    goal_type TEXT,
    target_value INTEGER,
    current_value INTEGER,
    completed INTEGER NOT NULL DEFAULT 0,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS daily_content_progress_entries (
    id TEXT PRIMARY KEY,
    content_type TEXT NOT NULL,
    date TEXT NOT NULL,
    category_id TEXT,
    item_id TEXT,
    completed INTEGER NOT NULL DEFAULT 0,
    payload_json TEXT,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS memory_attempt_entries (
    id TEXT PRIMARY KEY,
    content_type TEXT NOT NULL,
    item_id TEXT,
    score INTEGER,
    attempts_count INTEGER,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS custom_content_entries (
    id TEXT PRIMARY KEY,
    content_type TEXT NOT NULL,
    title TEXT,
    body TEXT,
    source TEXT,
    reference TEXT,
    grade TEXT,
    payload_json TEXT,
    created_at INTEGER,
    updated_at INTEGER
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS achievement_entries (
    id TEXT PRIMARY KEY,
    domain TEXT NOT NULL,
    achievement_key TEXT NOT NULL,
    unlocked_at INTEGER,
    payload_json TEXT
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS app_cache_entries (
    key TEXT PRIMARY KEY,
    cache_type TEXT NOT NULL,
    payload_json TEXT,
    updated_at INTEGER,
    expires_at INTEGER
  )
  ''',
];
