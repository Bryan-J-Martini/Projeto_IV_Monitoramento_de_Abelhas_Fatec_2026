import '../data/local/app_database.dart';
import '../data/local/database_tables.dart';

class MeliponicultorRepository {
  final AppDatabase _appDatabase;

  MeliponicultorRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<int> inserir({
    required String nome,
    required String email,
    required String senhaHash,
    required String endereco,
    required String nomeMeliponicultura,
  }) async {
    final database = await _appDatabase.database;

    return database.insert(DatabaseTables.meliponicultores, {
      DatabaseTables.nome: nome,
      DatabaseTables.email: email,
      DatabaseTables.senhaHash: senhaHash,
      DatabaseTables.endereco: endereco,
      DatabaseTables.nomeMeliponicultura: nomeMeliponicultura,
    });
  }

  Future<Map<String, dynamic>?> buscarPorId(int id) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.meliponicultores,
      where: '${DatabaseTables.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> buscarPorEmail(String email) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.meliponicultores,
      where: '${DatabaseTables.email} = ?',
      whereArgs: [email],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> listar() async {
    final database = await _appDatabase.database;
    return database.query(
      DatabaseTables.meliponicultores,
      orderBy: '${DatabaseTables.nome} COLLATE NOCASE',
    );
  }

  Future<int> atualizar({
    required int id,
    required String nome,
    required String email,
    required String endereco,
    required String nomeMeliponicultura,
    String? senhaHash,
  }) async {
    final database = await _appDatabase.database;
    final values = <String, dynamic>{
      DatabaseTables.nome: nome,
      DatabaseTables.email: email,
      DatabaseTables.endereco: endereco,
      DatabaseTables.nomeMeliponicultura: nomeMeliponicultura,
    };

    if (senhaHash != null) {
      values[DatabaseTables.senhaHash] = senhaHash;
    }

    return database.update(
      DatabaseTables.meliponicultores,
      values,
      where: '${DatabaseTables.id} = ?',
      whereArgs: [id],
    );
  }
}
