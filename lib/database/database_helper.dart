import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../app_state.dart';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            name TEXT,
            dateCreated TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE exercises (
            id TEXT PRIMARY KEY,
            routineId TEXT,
            name TEXT,
            FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
          )
        ''');

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

        await db.execute('''
          CREATE TABLE routines_completed (
            completionId INTEGER PRIMARY KEY AUTOINCREMENT,
            routineId TEXT,
            name TEXT,
            dateCompleted TEXT,
            duration INTEGER,
            totalVolume INTEGER,
            FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final tableInfo = await db.rawQuery('PRAGMA table_info(routines_completed)');
          final columnExists = tableInfo.any((column) => column['name'] == 'totalVolume');
          
          if (!columnExists) {
            await db.execute('''
              ALTER TABLE routines_completed ADD COLUMN totalVolume INTEGER
            ''');
          }
        }
      },
    );
  }

  // Métodos CRUD para Rutinas
  Future<void> insertRoutine(Routine routine) async {
    final db = await database;
    await db.insert('routines', {
      'id': routine.id,
      'name': routine.name,
      'dateCreated': routine.dateCreated.toIso8601String(),
    });
    print("Rutina guardada: ${routine.name}");

    for (var exercise in routine.exercises) {
      await insertExercise(exercise, routine.id);
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    final db = await database;
    await db.update(
      'routines',
      {
        'name': routine.name,
      },
      where: 'id = ?',
      whereArgs: [routine.id],
    );

    await db.delete('exercises', where: 'routineId = ?', whereArgs: [routine.id]);
    for (var exercise in routine.exercises) {
      await insertExercise(exercise, routine.id);
    }
  }

  Future<List<Routine>> getRoutines() async {
    final db = await database;
    final routinesData = await db.query('routines');
    final routines = <Routine>[];

    for (var routineData in routinesData) {
      final exercises = await getExercises(routineData['id'] as String);
      routines.add(Routine(
        id: routineData['id'] as String,
        name: routineData['name'] as String,
        dateCreated: DateTime.parse(routineData['dateCreated'] as String),
        exercises: exercises,
      ));
    }
    print("Rutinas cargadas: ${routines.length}");
    return routines;
  }

  Future<void> deleteRoutine(String id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
    print("Rutina eliminada: ID $id");
  }

  // Métodos CRUD para Ejercicios
  Future<void> insertExercise(Exercise exercise, String routineId) async {
    final db = await database;
    await db.insert('exercises', {
      'id': exercise.id,
      'routineId': routineId,
      'name': exercise.name,
    });
    print("Ejercicio guardado: ${exercise.name} para rutina ID: $routineId");

    for (var series in exercise.series) {
      await insertSeries(series, exercise.id);
    }
  }

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

  Future<void> deleteExercise(String id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    print("Ejercicio eliminado: ID $id");
  }

  // Métodos CRUD para Series
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

  Future<void> deleteSeries(int id) async {
    final db = await database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
    print("Serie eliminada: ID $id");
  }

  // Métodos para manejar rutinas completadas
  Future<void> insertCompletedRoutine(Routine routine, Duration duration, int totalVolume) async {
    final db = await database;
    await db.insert('routines_completed', {
      'routineId': routine.id,
      'name': routine.name,
      'dateCompleted': DateTime.now().toIso8601String(),
      'duration': duration.inSeconds,
      'totalVolume': totalVolume,
    });
    print("Rutina completada guardada: ${routine.name}");

    for (var exercise in routine.exercises) {
      await insertExercise(exercise, routine.id);
      for (var series in exercise.series) {
        await insertSeries(series, exercise.id);
      }
    }
  }

    Future<List<Map<String, dynamic>>> getCompletedRoutines() async {
    final db = await database;
    final completedRoutinesData = await db.query('routines_completed', orderBy: 'dateCompleted DESC');

    List<Map<String, dynamic>> completedRoutines = [];

    for (var routineData in completedRoutinesData) {
      final routineId = routineData['routineId'] as String;
      Map<String, dynamic> routine = Map<String, dynamic>.from(routineData);

      // Cargar ejercicios asociados a la rutina completada
      final exercisesData = await db.query('exercises', where: 'routineId = ?', whereArgs: [routineId]);
      List<Map<String, dynamic>> exercises = [];

      for (var exerciseData in exercisesData) {
        final exerciseId = exerciseData['id'] as String;
        Map<String, dynamic> exercise = Map<String, dynamic>.from(exerciseData);

        // Cargar series asociadas al ejercicio
        final seriesData = await db.query('series', where: 'exerciseId = ?', whereArgs: [exerciseId]);
        exercise['series'] = seriesData.map((seriesItem) {
          return {
            'weight': seriesItem['weight'],
            'reps': seriesItem['reps'],
            'perceivedExertion': seriesItem['perceivedExertion'],
            'isCompleted': seriesItem['isCompleted'] == 1,
          };
        }).toList();

        exercises.add(exercise);
      }

      routine['exercises'] = exercises;
      completedRoutines.add(routine);
      print("Rutina completada recuperada: ${routine['name']} con ${exercises.length} ejercicios");
    }

    return completedRoutines;
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'forge.db');

    await deleteDatabase(path);
    print("Base de datos eliminada por completo.");

    _database = null;
    await database;
    print("Base de datos recreada.");
  }
}
