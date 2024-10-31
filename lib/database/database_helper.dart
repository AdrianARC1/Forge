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
      version: 1,
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
    return routines;
  }

  Future<void> deleteRoutine(String id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos CRUD para Ejercicios
  Future<void> insertExercise(Exercise exercise, String routineId) async {
    final db = await database;
    await db.insert('exercises', {
      'id': exercise.id,
      'routineId': routineId,
      'name': exercise.name,
    });
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
    return exercises;
  }

  Future<void> deleteExercise(String id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
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
    return seriesList;
  }

  Future<void> deleteSeries(int id) async {
    final db = await database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }
}
