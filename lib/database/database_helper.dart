// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../app_state.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'forge.db');

    return await openDatabase(
      path,
      version: 3, // Incrementamos la versión a 3
      onCreate: (db, version) async {
        // Tabla de usuarios
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE,
            password TEXT
          )
        ''');

        // Tabla de rutinas unificada
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            userId TEXT,
            name TEXT,
            dateCreated TEXT,
            dateCompleted TEXT,
            duration INTEGER,
            totalVolume INTEGER,
            isCompleted INTEGER DEFAULT 0,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // Tabla de ejercicios
        await db.execute('''
          CREATE TABLE exercises (
            id TEXT PRIMARY KEY,
            routineId TEXT,
            name TEXT,
            FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
          )
        ''');

        // Tabla de series
        await db.execute('''
          CREATE TABLE series (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exerciseId TEXT,
            previousWeight INTEGER,
            previousReps INTEGER,
            lastSavedWeight INTEGER,
            lastSavedReps INTEGER,
            weight INTEGER,
            reps INTEGER,
            perceivedExertion INTEGER,
            isCompleted INTEGER,
            FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Si la versión anterior es menor que 3, realizamos las migraciones necesarias
          // Agregar columnas a la tabla routines
          await db.execute('ALTER TABLE routines ADD COLUMN userId TEXT');
          await db.execute('ALTER TABLE routines ADD COLUMN dateCompleted TEXT');
          await db.execute('ALTER TABLE routines ADD COLUMN duration INTEGER');
          await db.execute('ALTER TABLE routines ADD COLUMN totalVolume INTEGER');
          await db.execute('ALTER TABLE routines ADD COLUMN isCompleted INTEGER DEFAULT 0');

          // Crear tabla de usuarios si no existe
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              username TEXT UNIQUE,
              password TEXT
            )
          ''');

          // Eliminar la tabla routines_completed si existe
          await db.execute('DROP TABLE IF EXISTS routines_completed');
        }
      },
    );
  }

  // Métodos para manejar usuarios

  /// Registra un nuevo usuario
  Future<bool> registerUser(String username, String password) async {
    final db = await database;
    try {
      await db.insert('users', {
        'id': uuid.v4(),
        'username': username,
        'password': password,
      });
      print("Usuario registrado: $username");
      return true;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return false;
    }
  }

  /// Autentica un usuario
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      print("Usuario autenticado: $username");
      return result.first;
    }
    print("Error de autenticación para usuario: $username");
    return null;
  }

  // Métodos CRUD para Rutinas

  /// Inserta una nueva rutina
Future<void> insertRoutine(Routine routine, String userId) async {
  final db = await database;
  await db.insert('routines', {
    'id': routine.id,
    'userId': userId,
    'name': routine.name,
    'dateCreated': routine.dateCreated.toIso8601String(),
    'dateCompleted': routine.dateCompleted?.toIso8601String(),
    'duration': routine.duration.inSeconds,
    'totalVolume': routine.totalVolume,
    'isCompleted': routine.isCompleted ? 1 : 0,
  });
  print("Rutina guardada: ${routine.name}");

  for (var exercise in routine.exercises) {
    await insertExercise(exercise, routine.id);
  }
}


  /// Actualiza una rutina existente
  Future<void> updateRoutine(Routine routine, String userId) async {
    final db = await database;
    await db.update(
      'routines',
      {
        'name': routine.name,
        'dateCompleted': routine.dateCompleted?.toIso8601String(),
        'duration': routine.duration.inSeconds,
        'totalVolume': routine.totalVolume,
        'isCompleted': routine.isCompleted ? 1 : 0,
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [routine.id, userId],
    );

    // Eliminar ejercicios antiguos
    await db.delete('exercises', where: 'routineId = ?', whereArgs: [routine.id]);

    // Insertar ejercicios actualizados
    for (var exercise in routine.exercises) {
      await insertExercise(exercise, routine.id);
    }
  }

  /// Obtiene todas las rutinas no completadas del usuario
  Future<List<Routine>> getRoutines(String userId) async {
    final db = await database;
    final routinesData = await db.query(
      'routines',
      where: 'userId = ? AND isCompleted = 0',
      whereArgs: [userId],
    );
    final routines = <Routine>[];

    for (var routineData in routinesData) {
      final exercises = await getExercises(routineData['id'] as String);
      routines.add(Routine(
        id: routineData['id'] as String,
        name: routineData['name'] as String,
        dateCreated: DateTime.parse(routineData['dateCreated'] as String),
        exercises: exercises,
        isCompleted: (routineData['isCompleted'] as int) == 1,
      ));
    }
    print("Rutinas cargadas: ${routines.length}");
    return routines;
  }

  /// Obtiene todas las rutinas completadas del usuario
  Future<List<Routine>> getCompletedRoutines(String userId) async {
    final db = await database;
    final routinesData = await db.query(
      'routines',
      where: 'userId = ? AND isCompleted = 1',
      whereArgs: [userId],
      orderBy: 'dateCompleted DESC',
    );
    final routines = <Routine>[];

    for (var routineData in routinesData) {
      final exercises = await getExercises(routineData['id'] as String);
      routines.add(Routine(
        id: routineData['id'] as String,
        name: routineData['name'] as String,
        dateCreated: DateTime.parse(routineData['dateCreated'] as String),
        dateCompleted: DateTime.parse(routineData['dateCompleted'] as String),
        duration: Duration(seconds: routineData['duration'] as int),
        totalVolume: routineData['totalVolume'] as int,
        exercises: exercises,
        isCompleted: true,
      ));
    }
    print("Rutinas completadas cargadas: ${routines.length}");
    return routines;
  }

  /// Elimina una rutina
  Future<void> deleteRoutine(String id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
    print("Rutina eliminada: ID $id");
  }

  // Métodos CRUD para Ejercicios

  /// Inserta un nuevo ejercicio
  Future<void> insertExercise(Exercise exercise, String routineId) async {
    final db = await database;

    final String uniqueId = uuid.v4();

    await db.insert('exercises', {
      'id': uniqueId,
      'routineId': routineId,
      'name': exercise.name,
    });
    print("Ejercicio guardado: ${exercise.name} para rutina ID: $routineId con ID único $uniqueId");

    exercise.id = uniqueId;

    for (var series in exercise.series) {
      await insertSeries(series, uniqueId);
    }
  }

  /// Obtiene los ejercicios de una rutina
  Future<List<Exercise>> getExercises(String routineId) async {
    final db = await database;
    final exercisesData = await db.query('exercises', where: 'routineId = ?', whereArgs: [routineId]);
    final exercises = <Exercise>[];

    for (var exerciseData in exercisesData) {
      final series = await getSeries(exerciseData['id'] as String);
      exercises.add(Exercise(
        id: exerciseData['id'] as String,
        name: exerciseData['name'] as String,
        series: series,
      ));
    }
    print("Ejercicios cargados para rutina ID $routineId: ${exercises.length}");
    return exercises;
  }

  /// Elimina un ejercicio
  Future<void> deleteExercise(String id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    print("Ejercicio eliminado: ID $id");
  }

  // Métodos CRUD para Series

  /// Inserta una nueva serie
  Future<void> insertSeries(Series series, String exerciseId) async {
    final db = await database;
    await db.insert('series', {
      'exerciseId': exerciseId,
      'previousWeight': series.previousWeight,
      'previousReps': series.previousReps,
      'lastSavedWeight': series.lastSavedWeight,
      'lastSavedReps': series.lastSavedReps,
      'weight': series.weight,
      'reps': series.reps,
      'perceivedExertion': series.perceivedExertion,
      'isCompleted': series.isCompleted ? 1 : 0,
    });
    print("Serie guardada para ejercicio ID: $exerciseId con peso ${series.weight} y repeticiones ${series.reps}");
  }

  /// Obtiene las series de un ejercicio
  Future<List<Series>> getSeries(String exerciseId) async {
    final db = await database;
    final seriesData = await db.query('series', where: 'exerciseId = ?', whereArgs: [exerciseId]);
    final seriesList = <Series>[];

    for (var seriesItem in seriesData) {
      seriesList.add(Series(
        previousWeight: seriesItem['previousWeight'] as int?,
        previousReps: seriesItem['previousReps'] as int?,
        lastSavedWeight: seriesItem['lastSavedWeight'] as int?,
        lastSavedReps: seriesItem['lastSavedReps'] as int?,
        weight: seriesItem['weight'] as int,
        reps: seriesItem['reps'] as int,
        perceivedExertion: seriesItem['perceivedExertion'] as int,
        isCompleted: (seriesItem['isCompleted'] as int) == 1,
      ));
    }
    print("Series cargadas para ejercicio ID $exerciseId: ${seriesList.length}");
    return seriesList;
  }

  /// Elimina una serie
  Future<void> deleteSeries(int id) async {
    final db = await database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
    print("Serie eliminada: ID $id");
  }

  /// Reinicia la base de datos (solo para propósitos de desarrollo)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'forge.db');

    await deleteDatabase(path);
    print("Base de datos eliminada y recreada.");
  }
}
