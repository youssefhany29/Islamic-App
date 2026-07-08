import 'local_database_service.dart';

class HadithLocalRepository {
  HadithLocalRepository({
    LocalDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? LocalDatabaseService.instance;

  final LocalDatabaseService _databaseService;

  LocalDatabaseService get databaseService => _databaseService;
}
