import '../database/app_database.dart';
import '../database/daos/local_data_dao.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  AppDatabase? _database;

  AppDatabase get database {
    return _database ??= AppDatabase();
  }

  LocalDataDao get localDataDao => database.localDataDao;

  Future<void> close() async {
    final currentDatabase = _database;
    _database = null;

    if (currentDatabase != null) {
      await currentDatabase.close();
    }
  }
}
