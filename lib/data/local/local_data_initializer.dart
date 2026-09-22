import 'app_database.dart';

class LocalDataInitializer {
  LocalDataInitializer._();

  static final LocalDataInitializer instance = LocalDataInitializer._();

  Future<void>? _initialization;

  Future<void> ensureInitialized() {
    return _initialization ??= _openDatabase();
  }

  Future<void> _openDatabase() async {
    // O banco deve iniciar vazio. O primeiro registro será criado pelo cadastro.
    await AppDatabase.instance.database;
  }
}
