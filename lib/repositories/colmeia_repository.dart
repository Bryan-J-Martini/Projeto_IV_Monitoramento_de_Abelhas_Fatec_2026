import '../data/local/app_database.dart';
import '../data/local/database_tables.dart';

class ColmeiaRepository {
  final AppDatabase _appDatabase;

  ColmeiaRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<int> inserir({
    required String nome,
    required int meliponicultorId,
    required String especieAbelha,
    String ipAddress = '192.168.4.1',
    required String nomeRedeWifi,
    required String senhaRedeWifi,
    DateTime? dataCriacao,
  }) async {
    final database = await _appDatabase.database;

    return database.insert(DatabaseTables.colmeias, {
      DatabaseTables.nome: nome,
      DatabaseTables.meliponicultorId: meliponicultorId,
      DatabaseTables.especieAbelha: especieAbelha,
      DatabaseTables.ipAddress: ipAddress,
      DatabaseTables.nomeRedeWifi: nomeRedeWifi,
      DatabaseTables.senhaRedeWifi: senhaRedeWifi,
      DatabaseTables.dataCriacao:
          (dataCriacao ?? DateTime.now()).toIso8601String(),
      DatabaseTables.excluida: 0,
    });
  }

  Future<List<Map<String, dynamic>>> listarAtivas({int? meliponicultorId}) async {
    final database = await _appDatabase.database;
    final conditions = <String>['${DatabaseTables.excluida} = 0'];
    final arguments = <Object?>[];

    if (meliponicultorId != null) {
      conditions.add('${DatabaseTables.meliponicultorId} = ?');
      arguments.add(meliponicultorId);
    }

    return database.query(
      DatabaseTables.colmeias,
      where: conditions.join(' AND '),
      whereArgs: arguments,
      orderBy: '${DatabaseTables.dataCriacao} DESC',
    );
  }

  Future<Map<String, dynamic>?> buscarPorId(int id) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.colmeias,
      where: '${DatabaseTables.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<int> atualizar({
    required int id,
    required String nome,
    required String especieAbelha,
    String? ipAddress,
    required String nomeRedeWifi,
    required String senhaRedeWifi,
  }) async {
    final database = await _appDatabase.database;

    final values = <String, dynamic>{
      DatabaseTables.nome: nome,
      DatabaseTables.especieAbelha: especieAbelha,
      DatabaseTables.nomeRedeWifi: nomeRedeWifi,
      DatabaseTables.senhaRedeWifi: senhaRedeWifi,
    };
    if (ipAddress != null) values[DatabaseTables.ipAddress] = ipAddress;

    return database.update(
      DatabaseTables.colmeias,
      values,
      where: '${DatabaseTables.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> excluir(int id) async {
    final database = await _appDatabase.database;

    return database.update(
      DatabaseTables.colmeias,
      {DatabaseTables.excluida: 1},
      where: '${DatabaseTables.id} = ?',
      whereArgs: [id],
    );
  }
}
