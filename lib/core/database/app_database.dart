import 'package:drift/drift.dart';

import 'daos/local_data_dao.dart';
import 'database_connection.dart';
import 'migrations/app_migration_strategy.dart';

class AppDatabase {
  AppDatabase() : this.forExecutor(openAppDatabaseConnection());

  AppDatabase.forExecutor(this._executor) {
    localDataDao = LocalDataDao(this);
  }

  static const int schemaVersion = 1;

  final QueryExecutor _executor;
  late final LocalDataDao localDataDao;

  bool _initialized = false;

  Future<void> ensureOpen() async {
    if (_initialized) return;

    await _runCustom('PRAGMA foreign_keys = ON');
    await createSchemaV1IfNeeded(this);
    _initialized = true;
  }

  Future<void> runCustom(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    await ensureOpen();
    await _runCustom(statement, args);
  }

  Future<List<Map<String, Object?>>> runSelect(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    await ensureOpen();
    return _executor.runSelect(statement, args);
  }

  Future<int> runInsert(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    await ensureOpen();
    return _executor.runInsert(statement, args);
  }

  Future<int> runUpdate(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    await ensureOpen();
    return _executor.runUpdate(statement, args);
  }

  Future<int> runDelete(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    await ensureOpen();
    return _executor.runDelete(statement, args);
  }

  Future<void> runSchemaStatement(String statement) {
    return _runCustom(statement);
  }

  Future<void> close() {
    return _executor.close();
  }

  Future<void> _runCustom(
    String statement, [
    List<Object?> args = const [],
  ]) {
    return _executor.runCustom(statement, args);
  }
}
