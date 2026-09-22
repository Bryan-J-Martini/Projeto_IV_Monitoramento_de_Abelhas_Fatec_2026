import '../data/local/app_database.dart';
import '../data/local/database_tables.dart';

class DadoRepository {
  final AppDatabase _appDatabase;

  DadoRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<int> inserir({
    required int colmeiaId,
    required double temperatura,
    required int entrada,
    required int saida,
    DateTime? dataInsercao,
  }) async {
    final database = await _appDatabase.database;

    return database.insert(DatabaseTables.dados, {
      DatabaseTables.colmeiaId: colmeiaId,
      DatabaseTables.temperatura: temperatura,
      DatabaseTables.entrada: entrada,
      DatabaseTables.saida: saida,
      DatabaseTables.dataInsercao:
          (dataInsercao ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> listarPorColmeia(
    int colmeiaId, {
    int? limite,
  }) async {
    final database = await _appDatabase.database;

    return database.query(
      DatabaseTables.dados,
      where: '${DatabaseTables.colmeiaId} = ?',
      whereArgs: [colmeiaId],
      orderBy: '${DatabaseTables.dataInsercao} DESC',
      limit: limite,
    );
  }

  Future<Map<String, dynamic>?> buscarUltimoPorColmeia(int colmeiaId) async {
    final rows = await listarPorColmeia(colmeiaId, limite: 1);
    return rows.isEmpty ? null : rows.first;
  }
}
