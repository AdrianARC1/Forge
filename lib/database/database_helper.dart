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
      version: 4, // Incrementamos la versión a 4 para añadir 'salt'
      onCreate: (db, version) async {
        // Tabla de usuarios con salting y restricciones NOT NULL
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            salt TEXT NOT NULL
          )
        ''');

        // Tabla de rutinas unificada
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            name TEXT NOT NULL,
            dateCreated TEXT NOT NULL,
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
            routineId TEXT NOT NULL,
            name TEXT NOT NULL,
            FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
          )
        ''');

        // Tabla de series
        await db.execute('''
          CREATE TABLE series (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exerciseId TEXT NOT NULL,
            previousWeight INTEGER,
            previousReps INTEGER,
            lastSavedWeight INTEGER,
            lastSavedReps INTEGER,
            weight INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            perceivedExertion INTEGER NOT NULL,
            isCompleted INTEGER NOT NULL,
            FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          // Añadir 'salt' a la tabla de usuarios
          await db.execute('''
            ALTER TABLE users ADD COLUMN salt TEXT
          ''');

          // Actualizar existentes sin 'salt' (esto requiere definir cómo manejar usuarios existentes)
          // Por simplicidad, puedes optar por eliminar y recrear la tabla si estás en desarrollo
          // **Advertencia:** Este paso eliminará todos los datos existentes en la tabla 'users'
          
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              username TEXT UNIQUE NOT NULL,
              password TEXT NOT NULL,
              salt TEXT NOT NULL
            )
          ''');
          
          
          // Nota: En producción, deberías migrar los datos adecuadamente.
        }
      },
    );
  }

  // Métodos para manejar usuarios

  /// Registra un nuevo usuario con salting
  Future<bool> registerUser(String username, String password, String salt) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      print("Error: Usuario o contraseña vacíos.");
      return false;
    }

    final db = await database;
    try {
      await db.insert('users', {
        'id': uuid.v4(),
        'username': username.trim(),
        'password': password.trim(),
        'salt': salt.trim(),
      });
      print("Usuario registrado: $username");
      return true;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return false;
    }
  }

  /// Autentica un usuario y retorna sus datos incluyendo el salt
  Future<Map<String, dynamic>?> loginUser(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isNotEmpty) {
      print("Usuario encontrado: $username");
      return result.first;
    }
    print("Usuario no encontrado: $username");
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
        id: seriesItem['id']?.toString() ?? uuid.v4(),
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
