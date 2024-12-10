import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'package:forge/api/exercise_db_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Series {
  String id;
  int? previousWeight;
  int? previousReps;
  int? lastSavedWeight;
  int? lastSavedReps;
  int weight;
  int reps;
  int perceivedExertion;
  int? lastSavedPerceivedExertion;
  bool isCompleted;

  Series({
    required this.id,
    this.previousWeight,
    this.previousReps,
    this.lastSavedWeight,
    this.lastSavedReps,
    required this.weight,
    required this.reps,
    required this.perceivedExertion,
    this.lastSavedPerceivedExertion,
    this.isCompleted = false,
  });
}

class Exercise {
  String id;
  final String name;
  final String? gifUrl;
  List<Series> series;

  Exercise({required this.id, required this.name, this.gifUrl, this.series = const []});
}

class Routine {
  final String id;
  final String name;
  final DateTime dateCreated;
  DateTime? dateCompleted;
  List<Exercise> exercises;
  Duration duration;
  int totalVolume;
  bool isCompleted;
  String? notes;

  Routine({
    required this.id,
    required this.name,
    required this.dateCreated,
    this.dateCompleted,
    this.exercises = const [],
    this.duration = Duration.zero,
    this.totalVolume = 0,
    this.isCompleted = false,
    this.notes,
  });

  Routine copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    Duration? duration,
    bool? isCompleted,
    DateTime? dateCompleted,
    int? totalVolume,
    String? notes,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      dateCreated: dateCreated,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      totalVolume: totalVolume ?? this.totalVolume,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
}

class AppState with ChangeNotifier {
  List<Routine> _routines = [];
  List<Routine> _completedRoutines = [];

  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  List<Map<String, dynamic>> _visibleExercises = [];
  final int _exercisesPerPage = 20;
  int _currentPage = 0;

  List<String> _muscleGroups = [];
  List<String> _equipment = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ExerciseDbApiService _apiService = ExerciseDbApiService();

  Routine? minimizedRoutine;
  Routine? savedRoutineState;
  Duration minimizedRoutineDuration = Duration.zero;
  Timer? _timer;

  String? _userId;
  String? get userId => _userId;
  String? _username;
  String? get username => _username;

  String? _profileImagePath;
  String? get profileImagePath => _profileImagePath;

  bool _showTutorial = false;
  bool get showTutorial => _showTutorial;
  bool _hasSeenTutorial = false;
  bool get hasSeenTutorial => _hasSeenTutorial;

  List<Routine> get routines => _routines;
  List<Routine> get completedRoutines => _completedRoutines;
  List<Map<String, dynamic>> get exercises => _visibleExercises;
  List<String> get muscleGroups => _muscleGroups;
  List<String> get equipment => _equipment;

  Map<String, Map<String, dynamic>> _maxExerciseRecords = {};
  Map<String, Map<String, dynamic>> get maxExerciseRecords => _maxExerciseRecords;

  AppState() {
    _initializeApp();
  }

Future<void> _initializeApp() async {
    try {
      await _loadUserSession();
      await _loadTutorialStatus();
    } catch (e) {
      // Error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTutorialStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasSeenTutorial = true;
    await prefs.setBool('hasSeenTutorial', true);
    notifyListeners();
  }

  Future<void> resetTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasSeenTutorial = false;
    await prefs.setBool('hasSeenTutorial', false);
    notifyListeners();
  }
  Future<void> _loadUserSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      _username = prefs.getString('username');
      _profileImagePath = prefs.getString('profileImagePath');

      if (_userId != null) {
        await _loadRoutines();
        await _loadCompletedRoutines();
        await loadMuscleGroups();
        await loadEquipment();
        await fetchAllExercises();
        await loadMaxExerciseRecords();
      }
    } catch (e) {
      // Error
    }
  }

  Future<void> updateProfileImage(String path) async {
    _profileImagePath = path;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', path);
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
  if (_userId != null) {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'username': newUsername.trim()},
      where: 'id = ?',
      whereArgs: [_userId],
    );

    _username = newUsername.trim();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username!);

    notifyListeners();
  }
}

Future<void> updatePassword(String newPassword) async {
  if (_userId != null) {
    String salt = generateSalt();
    String hashedPassword = hashPassword(newPassword, salt);

    final db = await _dbHelper.database;
    await db.update(
      'users',
      {
        'password': hashedPassword,
        'salt': salt,
      },
      where: 'id = ?',
      whereArgs: [_userId],
    );
  }
}

Future<bool> validateCurrentPassword(String currentPassword) async {
  if (_userId == null || _username == null) return false;
  final user = await _dbHelper.loginUser(_username!);
  if (user == null) return false;

  String storedHashedPassword = user['password'] as String;
  String salt = user['salt'] as String;
  String hashedInputPassword = hashPassword(currentPassword.trim(), salt);

  return hashedInputPassword == storedHashedPassword;
}


  List<Map<String, dynamic>> getPersonalRecords() {
    List<Map<String, dynamic>> recordsList = [];
    _maxExerciseRecords.forEach((exerciseName, recordData) {
      int maxWeight = recordData['maxWeight'] as int;
      double max1RM = recordData['max1RM'] as double;
      int maxReps = recordData['maxReps'] as int;
      String? gifUrl = getExerciseGifUrl(exerciseName);
      recordsList.add({
        'exerciseName': exerciseName,
        'gifUrl': gifUrl,
        'maxWeight': maxWeight,
        'maxReps': maxReps,
        'max1RM': max1RM,
      });
    });
    recordsList.sort((a, b) => (b['maxWeight'] as int).compareTo(a['maxWeight'] as int));
    return recordsList;
  }

  String? getExerciseGifUrl(String exerciseName) {
    for (var ex in _allExercises) {
      if ((ex['name'] as String).toLowerCase() == exerciseName.toLowerCase()) {
        return ex['gifUrl'] as String?;
      }
    }
    return null;
  }

  String generateSalt([int length = 16]) {
    final Random random = Random.secure();
    final List<int> saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  Future<bool> register(String username, String password) async {
    String trimmedUsername = username.trim();
    String trimmedPassword = password.trim();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
      return false;
    }

    if (trimmedPassword.length < 6) {
      return false;
    }

    String salt = generateSalt();
    String hashedPassword = hashPassword(trimmedPassword, salt);
    bool success = await _dbHelper.registerUser(trimmedUsername, hashedPassword, salt);
    if (success) {
      await login(trimmedUsername, trimmedPassword);
      _showTutorial = true;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    String trimmedUsername = username.trim();
    String trimmedPassword = password.trim();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
      return false;
    }

    final user = await _dbHelper.loginUser(trimmedUsername);
    if (user != null) {
      String storedHashedPassword = user['password'] as String;
      String salt = user['salt'] as String;
      String hashedInputPassword = hashPassword(trimmedPassword, salt);

      if (hashedInputPassword == storedHashedPassword) {
        _userId = user['id'] as String;
        _username = user['username'] as String;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _userId!);
        await prefs.setString('username', _username!);

        await _loadRoutines();
        await _loadCompletedRoutines();
        await loadMuscleGroups();
        await loadEquipment();
        await fetchAllExercises();
        await loadMaxExerciseRecords();
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('profileImagePath');

    _userId = null;
    _username = null;
    _profileImagePath = null;
    _routines = [];
    _completedRoutines = [];
    _allExercises = [];
    _filteredExercises = [];
    _visibleExercises = [];
    _currentPage = 0;
    _maxExerciseRecords = {};
    notifyListeners();
  }

  void startRoutineTimer() {
    stopRoutineTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      minimizedRoutineDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void stopRoutineTimer() {
    _timer?.cancel();
  }

  void minimizeRoutine(Routine routine) {
    savedRoutineState = routine;
    minimizedRoutine = routine;
    startRoutineTimer();
    notifyListeners();
  }

  void restoreRoutine() {
    minimizedRoutine = null;
    savedRoutineState = null;
    stopRoutineTimer();
    notifyListeners();
  }

  void cancelMinimizedRoutine() {
    minimizedRoutine = null;
    savedRoutineState = null;
    minimizedRoutineDuration = Duration.zero;
    stopRoutineTimer();
    notifyListeners();
  }

  Future<void> fetchAllExercises() async {
    try {
      if (_allExercises.isEmpty) {
        _allExercises = await _apiService.fetchExercises();
        _filteredExercises = _allExercises;
        _visibleExercises.clear();
        _currentPage = 0;
        _loadMoreExercises();
        notifyListeners();
      }
    } catch (e) {
      // Error
    }
  }

  void _loadMoreExercises() {
    int startIndex = _currentPage * _exercisesPerPage;
    int endIndex = startIndex + _exercisesPerPage;
    if (startIndex < _filteredExercises.length) {
      _visibleExercises.addAll(
        _filteredExercises.sublist(startIndex, endIndex.clamp(0, _filteredExercises.length))
      );
      _currentPage++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void loadMoreExercises() {
    _loadMoreExercises();
  }

  void filterExercises(String query) {
    if (query.isEmpty) {
      _filteredExercises = _allExercises;
    } else {
      _filteredExercises = _allExercises
          .where((exercise) =>
              (exercise['name'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _visibleExercises.clear();
    _currentPage = 0;
    _loadMoreExercises();
  }

  void applyFilters({String? muscleGroup, String? equipment}) {
    _filteredExercises = _allExercises.where((exercise) {
      bool matchesMuscle = muscleGroup == null || (exercise['target'] == muscleGroup);
      bool matchesEquipment = equipment == null || (exercise['equipment'] == equipment);
      return matchesMuscle && matchesEquipment;
    }).toList();
    _visibleExercises.clear();
    _currentPage = 0;
    _loadMoreExercises();
  }

  Future<void> loadMuscleGroups() async {
    try {
      _muscleGroups = await _apiService.fetchMuscleGroups();
      notifyListeners();
    } catch (e) {
      // Error
    }
  }

  Future<void> loadEquipment() async {
    try {
      _equipment = await _apiService.fetchEquipmentList();
      notifyListeners();
    } catch (e) {
      // Error
    }
  }

  Future<void> _loadRoutines() async {
    if (_userId != null) {
      try {
        _routines = await _dbHelper.getRoutines(_userId!);
      } catch (e) {
      // Error
    }
      notifyListeners();
    }
  }

  Future<void> _loadCompletedRoutines() async {
    if (_userId != null) {
      try {
        _completedRoutines = await _dbHelper.getCompletedRoutines(_userId!);
      } catch (e) {
      // Error
    }
      notifyListeners();
    }
  }

  Future<void> loadMaxExerciseRecords() async {
    if (_userId != null) {
      try {
        final records = await _dbHelper.getAllExerciseRecords(_userId!);
        _maxExerciseRecords = {
          for (var record in records)
            record['exerciseName'] as String: record,
        };
        notifyListeners();
      } catch (e) {
      // Error
    }
    }
  }

  Future<void> completeRoutine(Routine routine, Duration duration) async {
    try {
      int totalVolume = calculateTotalVolume(routine);

      Routine completedRoutine = routine.copyWith(
        id: uuid.v4(),
        isCompleted: true,
        dateCompleted: DateTime.now(),
        duration: duration,
        totalVolume: totalVolume,
      );

      await _dbHelper.insertRoutine(completedRoutine, _userId!);
      await updateMaxRecordsFromRoutine(completedRoutine);
      await _loadCompletedRoutines();
    } catch (e) {
      // Error
    }
  }

  Future<void> updateMaxRecordsFromRoutine(Routine routine) async {
    if (_userId != null) {
      for (var exercise in routine.exercises) {
        for (var series in exercise.series) {
          double new1RM = series.weight * (1 + series.reps / 30);
          Map<String, dynamic>? existingRecord = _maxExerciseRecords[exercise.name];
          if (existingRecord == null || new1RM > (existingRecord['max1RM'] as double)) {
            await _dbHelper.updateExerciseRecord(_userId!, exercise.name, series.weight, series.reps);
            _maxExerciseRecords[exercise.name] = {
              'maxWeight': series.weight,
              'maxReps': series.reps,
              'max1RM': new1RM,
            };
          }
        }
      }
      notifyListeners();
    }
  }

  Future<void> saveRoutine(Routine routine) async {
    if (_userId != null) {
      try {
        await _dbHelper.insertRoutine(routine, _userId!);
        _routines.add(routine);
        notifyListeners();
      } catch (e) {
      // Error
    }
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    if (_userId != null) {
      try {
        await _dbHelper.updateRoutine(routine, _userId!);
        final index = _routines.indexWhere((r) => r.id == routine.id);
        if (index != -1) {
          _routines[index] = routine;
          notifyListeners();
        }
      } catch (e) {
      // Error
    }
    }
  }

  Future<void> addExerciseToRoutine(Exercise exercise, String routineId) async {
    try {
      await _dbHelper.insertExercise(exercise, routineId);
      final routine = _routines.firstWhere((routine) => routine.id == routineId);
      routine.exercises.add(exercise);
      notifyListeners();
    } catch (e) {
      // Error
    }
  }

  Future<void> addSeriesToExercise(Series series, String exerciseId) async {
    try {
      series.lastSavedPerceivedExertion = series.perceivedExertion;
      await _dbHelper.insertSeries(series, exerciseId);
      final exercise = _routines.expand((r) => r.exercises).firstWhere((e) => e.id == exerciseId);
      exercise.series.add(series);
      notifyListeners();
    } catch (e) {
      // Error
    }
  }

  void updateRoutineDuration(String routineId, Duration duration) {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      routine.duration = duration;
      notifyListeners();
    } catch (e) {
      // Error
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      await _dbHelper.deleteRoutine(id);
      _routines.removeWhere((routine) => routine.id == id);
      notifyListeners();
    } catch (e) {
      // Error
    }
  }

  Future<String> exportUserData() async {
    if (_userId == null) {
      return '';
    }

    final db = await _dbHelper.database;

    // Obtener datos del usuario
    final userData = <String, dynamic>{};
    userData['userId'] = _userId;
    userData['username'] = _username;

    // Routines (tanto completadas como no completadas)
    final allRoutines = await db.query('routines', where: 'userId = ?', whereArgs: [_userId]);
    userData['routines'] = allRoutines;

    // Ejercicios
    final exercises = await db.query('exercises');
    userData['exercises'] = exercises;

    // Series
    final series = await db.query('series');
    userData['series'] = series;

    // Records de ejercicios
    final exerciseRecords = await db.query('exercise_records', where: 'userId = ?', whereArgs: [_userId]);
    userData['exerciseRecords'] = exerciseRecords;

    // Convertir a JSON
    return jsonEncode(userData);
  }

  int calculateTotalVolume(Routine routine) {
    int totalVolume = 0;
    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalVolume += series.weight * series.reps;
      }
    }
    return totalVolume;
  }
}
