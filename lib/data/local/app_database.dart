import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(
      databasesPath,
      DatabaseTables.databaseName,
    );

    return openDatabase(
      databasePath,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE ${DatabaseTables.meliponicultores} (
            ${DatabaseTables.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DatabaseTables.nome} TEXT NOT NULL,
            ${DatabaseTables.email} TEXT NOT NULL UNIQUE,
            ${DatabaseTables.senhaHash} TEXT NOT NULL,
            ${DatabaseTables.endereco} TEXT NOT NULL,
            ${DatabaseTables.nomeMeliponicultura} TEXT NOT NULL
          )
        ''');

        await database.execute('''
          CREATE TABLE ${DatabaseTables.colmeias} (
            ${DatabaseTables.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DatabaseTables.nome} TEXT NOT NULL,
            ${DatabaseTables.meliponicultorId} INTEGER NOT NULL,
            ${DatabaseTables.especieAbelha} TEXT NOT NULL,
            ${DatabaseTables.ipAddress} TEXT NOT NULL DEFAULT '192.168.4.1',
            ${DatabaseTables.nomeRedeWifi} TEXT NOT NULL,
            ${DatabaseTables.senhaRedeWifi} TEXT NOT NULL,
            ${DatabaseTables.dataCriacao} TEXT NOT NULL,
            ${DatabaseTables.excluida} INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (${DatabaseTables.meliponicultorId})
              REFERENCES ${DatabaseTables.meliponicultores} (${DatabaseTables.id})
              ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE TABLE ${DatabaseTables.dados} (
            ${DatabaseTables.id} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${DatabaseTables.colmeiaId} INTEGER NOT NULL,
            ${DatabaseTables.temperatura} REAL NOT NULL,
            ${DatabaseTables.entrada} INTEGER NOT NULL,
            ${DatabaseTables.saida} INTEGER NOT NULL,
            ${DatabaseTables.dataInsercao} TEXT NOT NULL,
            FOREIGN KEY (${DatabaseTables.colmeiaId})
              REFERENCES ${DatabaseTables.colmeias} (${DatabaseTables.id})
              ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE INDEX idx_colmeias_meliponicultor
          ON ${DatabaseTables.colmeias} (${DatabaseTables.meliponicultorId})
        ''');

        await database.execute('''
          CREATE INDEX idx_dados_colmeia_data
          ON ${DatabaseTables.dados}
            (${DatabaseTables.colmeiaId}, ${DatabaseTables.dataInsercao})
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            ALTER TABLE ${DatabaseTables.colmeias}
            ADD COLUMN ${DatabaseTables.ipAddress}
              TEXT NOT NULL DEFAULT '192.168.4.1'
          ''');
        }
      },
    );
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) return;

    await database.close();
    _database = null;
  }
}
