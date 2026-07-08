import 'local_database_service.dart';

class AzkarLocalRepository {
  AzkarLocalRepository({
    LocalDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? LocalDatabaseService.instance;

  final LocalDatabaseService _databaseService;

  LocalDatabaseService get databaseService => _databaseService;
}
