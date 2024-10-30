import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:forge/app_state.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'forge_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routines(
        id TEXT PRIMARY KEY,
        name TEXT,
        dateCreated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE history(
        id TEXT PRIMARY KEY,
        name TEXT,
        dateCreated TEXT
      )
    ''');
  }

  // Crear una nueva rutina
  Future<void> insertRoutine(Routine routine) async {
    final db = await database;
    await db.insert(
      'routines',
      {
        'id': routine.id,
        'name': routine.name,
        'dateCreated': routine.dateCreated.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todas las rutinas
  Future<List<Routine>> getRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('routines');
    return List.generate(maps.length, (i) {
      return Routine(
        id: maps[i]['id'],
        name: maps[i]['name'],
        dateCreated: DateTime.parse(maps[i]['dateCreated']),
      );
    });
  }

  // Eliminar una rutina
  Future<void> deleteRoutine(String id) async {
    final db = await database;
    await db.delete(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
