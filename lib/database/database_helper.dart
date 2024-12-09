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

  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    final List<Map<String, dynamic>> tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    return tableInfo.any((column) => column['name'] == columnName);
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'forge.db');

    return await openDatabase(
      path,
      version: 9, // versión con notes
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            salt TEXT NOT NULL
          )
        ''');

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
            notes TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE exercises (
            id TEXT PRIMARY KEY,
            routineId TEXT NOT NULL,
            name TEXT NOT NULL,
            gifUrl TEXT,
            FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE series (
            id TEXT PRIMARY KEY,
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

        await db.execute('''
          CREATE TABLE exercise_records (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            exerciseName TEXT NOT NULL,
            maxWeight INTEGER NOT NULL,
            maxReps INTEGER NOT NULL,
            max1RM REAL NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          await db.execute('''
            ALTER TABLE series RENAME TO series_old;
          ''');

          await db.execute('''
            CREATE TABLE series (
              id TEXT PRIMARY KEY,
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

          await db.execute('''
            INSERT INTO series (id, exerciseId, previousWeight, previousReps, lastSavedWeight, lastSavedReps, weight, reps, perceivedExertion, isCompleted)
            SELECT id, exerciseId, previousWeight, previousReps, lastSavedWeight, lastSavedReps, weight, reps, perceivedExertion, isCompleted
            FROM series_old;
          ''');

          await db.execute('DROP TABLE series_old;');
        }

        if (oldVersion < 7) {
          bool durationExists = await _columnExists(db, 'routines', 'duration');
          if (!durationExists) {
            await db.execute('ALTER TABLE routines ADD COLUMN duration INTEGER');
          }
        }

        if (oldVersion < 8) {
          bool gifUrlExists = await _columnExists(db, 'exercises', 'gifUrl');
          if (!gifUrlExists) {
            await db.execute('ALTER TABLE exercises ADD COLUMN gifUrl TEXT');
          }
        }

        if (oldVersion < 9) {
          bool notesExists = await _columnExists(db, 'routines', 'notes');
          if (!notesExists) {
            await db.execute('ALTER TABLE routines ADD COLUMN notes TEXT');
          }
        }
      },
    );
  }

  Future<bool> registerUser(String username, String password, String salt) async {
    final db = await database;
    try {
      await db.insert('users', {
        'id': uuid.v4(),
        'username': username.trim(),
        'password': password.trim(),
        'salt': salt.trim(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String username) async {
    final db = await database;
    final result = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

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
      'notes': routine.notes,
    });

    for (var exercise in routine.exercises) {
      await insertExercise(exercise, routine.id);
    }
  }

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
        'notes': routine.notes,
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [routine.id, userId],
    );

    await db.delete('exercises', where: 'routineId = ?', whereArgs: [routine.id]);
    for (var exercise in routine.exercises) {
      await insertExercise(exercise, routine.id);
    }
  }

  Future<List<Routine>> getRoutines(String userId) async {
    final db = await database;
    final routinesData = await db.query('routines', where: 'userId = ? AND isCompleted = 0', whereArgs: [userId]);
    final routines = <Routine>[];

    for (var routineData in routinesData) {
      final exercises = await getExercises(routineData['id'] as String);
      routines.add(Routine(
        id: routineData['id'] as String,
        name: routineData['name'] as String,
        dateCreated: DateTime.parse(routineData['dateCreated'] as String),
        exercises: exercises,
        isCompleted: (routineData['isCompleted'] as int) == 1,
        duration: (routineData['duration'] != null) ? Duration(seconds: routineData['duration'] as int) : Duration.zero,
        totalVolume: routineData['totalVolume'] as int? ?? 0,
        notes: routineData['notes'] as String?,
      ));
    }
    return routines;
  }

  Future<List<Routine>> getCompletedRoutines(String userId) async {
    final db = await database;
    final routinesData = await db.query(
      'routines',
      where: 'userId = ? AND isCompleted = 1',
      whereArgs: [userId],
      orderBy: 'dateCompleted DESC',
      limit: 10,
    );
    final routines = <Routine>[];

    for (var routineData in routinesData) {
      final exercises = await getExercises(routineData['id'] as String);
      routines.add(Routine(
        id: routineData['id'] as String,
        name: routineData['name'] as String,
        dateCreated: DateTime.parse(routineData['dateCreated'] as String),
        dateCompleted: routineData['dateCompleted'] != null ? DateTime.parse(routineData['dateCompleted'] as String) : null,
        duration: (routineData['duration'] != null) ? Duration(seconds: routineData['duration'] as int) : Duration.zero,
        totalVolume: routineData['totalVolume'] as int? ?? 0,
        exercises: exercises,
        isCompleted: true,
        notes: routineData['notes'] as String?,
      ));
    }
    return routines;
  }

  Future<void> deleteRoutine(String id) async {
    final db = await database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertExercise(Exercise exercise, String routineId) async {
    final db = await database;
    final String uniqueId = uuid.v4();
    await db.insert('exercises', {
      'id': uniqueId,
      'routineId': routineId,
      'name': exercise.name,
      'gifUrl': exercise.gifUrl,
    });
    exercise.id = uniqueId;
    for (var series in exercise.series) {
      await insertSeries(series, uniqueId);
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
        gifUrl: exerciseData['gifUrl'] as String?,
        series: series,
      ));
    }
    return exercises;
  }

  Future<void> deleteExercise(String id) async {
    final db = await database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertSeries(Series series, String exerciseId) async {
    final db = await database;
    await db.insert('series', {
      'id': series.id,
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
    return seriesList;
  }

  Future<void> deleteSeries(int id) async {
    final db = await database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getExerciseRecord(String userId, String exerciseName) async {
    final db = await database;
    final result = await db.query(
      'exercise_records',
      where: 'userId = ? AND exerciseName = ?',
      whereArgs: [userId, exerciseName],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<void> updateExerciseRecord(String userId, String exerciseName, int weight, int reps) async {
    final db = await database;
    double new1RM = weight * (1 + reps / 30);
    final existingRecord = await getExerciseRecord(userId, exerciseName);
    if (existingRecord == null) {
      await db.insert('exercise_records', {
        'id': uuid.v4(),
        'userId': userId,
        'exerciseName': exerciseName,
        'maxWeight': weight,
        'maxReps': reps,
        'max1RM': new1RM,
      });
    } else {
      double existing1RM = existingRecord['max1RM'] as double;
      if (new1RM > existing1RM) {
        await db.update(
          'exercise_records',
          {
            'maxWeight': weight,
            'maxReps': reps,
            'max1RM': new1RM,
          },
          where: 'id = ?',
          whereArgs: [existingRecord['id']],
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAllExerciseRecords(String userId) async {
    final db = await database;
    final result = await db.query('exercise_records', where: 'userId = ?', whereArgs: [userId]);
    return result;
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'forge.db');
    await deleteDatabase(path);
  }
}
