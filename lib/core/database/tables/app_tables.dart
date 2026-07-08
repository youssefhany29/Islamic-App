import 'package:drift/drift.dart';

class FavoriteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuranProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get progressType => text()();
  IntColumn get surahNumber => integer().nullable()();
  IntColumn get ayahNumber => integer().nullable()();
  IntColumn get pageNumber => integer().nullable()();
  IntColumn get juzNumber => integer().nullable()();
  TextColumn get planId => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuranBookmarkEntries extends Table {
  TextColumn get id => text()();
  IntColumn get surahNumber => integer().nullable()();
  IntColumn get ayahNumber => integer().nullable()();
  IntColumn get pageNumber => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuranWirdPlanEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuranWirdProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  IntColumn get surahNumber => integer().nullable()();
  IntColumn get ayahNumber => integer().nullable()();
  IntColumn get pageNumber => integer().nullable()();
  IntColumn get completedPages => integer().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PrayerTrackingDays extends Table {
  TextColumn get date => text()();
  BoolColumn get fajrDone => boolean().withDefault(const Constant(false))();
  BoolColumn get dhuhrDone => boolean().withDefault(const Constant(false))();
  BoolColumn get asrDone => boolean().withDefault(const Constant(false))();
  BoolColumn get maghribDone => boolean().withDefault(const Constant(false))();
  BoolColumn get ishaDone => boolean().withDefault(const Constant(false))();
  BoolColumn get completedToday => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}

class PrayerTrackingStats extends Table {
  TextColumn get id => text()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get bestStreak => integer().withDefault(const Constant(0))();
  TextColumn get lastDate => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NightPrayerTrackingDays extends Table {
  TextColumn get date => text()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  BoolColumn get completedToday => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}

class RawatibTrackingDays extends Table {
  TextColumn get date => text()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}

class MemorizationPlanEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get status => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MemorizationTaskEntries extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text().nullable()();
  DateTimeColumn get taskDate => dateTime().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MemorizationProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().nullable()();
  TextColumn get planId => text().nullable()();
  TextColumn get status => text().nullable()();
  IntColumn get mistakesCount => integer().nullable()();
  IntColumn get reviewLevel => integer().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MemorizationSessionResultEntries extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text().nullable()();
  TextColumn get taskId => text().nullable()();
  IntColumn get score => integer().nullable()();
  IntColumn get mistakesCount => integer().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecitationProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get source => text().nullable()();
  IntColumn get reciterId => integer().nullable()();
  IntColumn get surahNumber => integer().nullable()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get lastListenedAt => integer().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecitationHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get source => text().nullable()();
  IntColumn get reciterId => integer().nullable()();
  IntColumn get surahNumber => integer().nullable()();
  IntColumn get listenedSeconds => integer().withDefault(const Constant(0))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecitationStatsEntries extends Table {
  TextColumn get id => text()();
  IntColumn get totalSeconds => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  IntColumn get bestStreak => integer().withDefault(const Constant(0))();
  TextColumn get lastActiveDate => text().nullable()();
  IntColumn get dailyGoalSeconds => integer().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecitationFavoriteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get source => text().nullable()();
  IntColumn get reciterId => integer().nullable()();
  IntColumn get surahNumber => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecitationDownloadEntries extends Table {
  TextColumn get id => text()();
  TextColumn get source => text().nullable()();
  IntColumn get reciterId => integer().nullable()();
  IntColumn get surahNumber => integer().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecitationCustomGoalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get goalType => text().nullable()();
  IntColumn get targetValue => integer().nullable()();
  IntColumn get currentValue => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DailyContentProgressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get contentType => text()();
  TextColumn get date => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get itemId => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MemoryAttemptEntries extends Table {
  TextColumn get id => text()();
  TextColumn get contentType => text()();
  TextColumn get itemId => text().nullable()();
  IntColumn get score => integer().nullable()();
  IntColumn get attemptsCount => integer().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CustomContentEntries extends Table {
  TextColumn get id => text()();
  TextColumn get contentType => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get grade => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AchievementEntries extends Table {
  TextColumn get id => text()();
  TextColumn get domain => text()();
  TextColumn get achievementKey => text()();
  DateTimeColumn get unlockedAt => dateTime().nullable()();
  TextColumn get payloadJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppCacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get cacheType => text()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
