import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'api/wger_api_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
  String? id;
  final String name;
  List<Series> series;

  Exercise({this.id, required this.name, this.series = const []});
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

  Routine({
    required this.id,
    required this.name,
    required this.dateCreated,
    this.dateCompleted,
    this.exercises = const [],
    this.duration = Duration.zero,
    this.totalVolume = 0,
    this.isCompleted = false,
  });

  Routine copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    Duration? duration,
    bool? isCompleted,
    DateTime? dateCompleted,
    int? totalVolume,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      dateCreated: this.dateCreated,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      totalVolume: totalVolume ?? this.totalVolume,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}


class AppState with ChangeNotifier {
  List<Routine> _routines = [];
  List<Routine> _completedRoutines = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _muscleGroups = [];
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WgerApiService _apiService = WgerApiService();

  Routine? minimizedRoutine;
  Routine? savedRoutineState; // Guarda el estado de la rutina minimizada
  Duration minimizedRoutineDuration = Duration.zero;
  Timer? _timer;

  // Propiedades del usuario
  String? _userId;
  String? get userId => _userId;
  String? _username;
  String? get username => _username;

  bool _showTutorial = false;
  bool get showTutorial => _showTutorial;

  List<Routine> get routines => _routines;
  List<Routine> get completedRoutines => _completedRoutines;
  List<Map<String, dynamic>> get exercises => _exercises;
  List<Map<String, dynamic>> get muscleGroups => _muscleGroups;
  List<Map<String, dynamic>> get equipment => _equipment;

   AppState() {
    _initializeApp();
  }

Future<void> _initializeApp() async {
  await Future.delayed(Duration(seconds: 2)); // Espera 2 segundos
  await _loadUserSession();
  _isLoading = false;
  notifyListeners();
}


  Future<void> _loadUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');

    if (_userId != null) {
      await _loadRoutines();
      await _loadCompletedRoutines();
      loadMuscleGroups();
      loadEquipment();
    }
    notifyListeners();
  }

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<bool> register(String username, String password) async {
    String hashedPassword = hashPassword(password);
    bool success = await _dbHelper.registerUser(username, hashedPassword);
    if (success) {
      await login(username, password);
      _showTutorial = true;
      return true;
    } else {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    String hashedPassword = hashPassword(password);
    final user = await _dbHelper.loginUser(username, hashedPassword);
    if (user != null) {
      _userId = user['id'] as String;
      _username = user['username'] as String;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _userId!);
      await prefs.setString('username', _username!);

      await _loadRoutines();
      await _loadCompletedRoutines();
      loadMuscleGroups();
      loadEquipment();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('username');

    _userId = null;
    _username = null;
    _routines = [];
    _completedRoutines = [];
    notifyListeners();
  }

  void completeTutorial() {
    _showTutorial = false;
    notifyListeners();
  }

  // Inicia el temporizador para la rutina minimizada
  void startRoutineTimer() {
    stopRoutineTimer(); // Detener cualquier temporizador anterior
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      minimizedRoutineDuration += Duration(seconds: 1);
      notifyListeners();
    });
  }

  // Detener el temporizador
  void stopRoutineTimer() {
    _timer?.cancel();
  }

  // Minimiza la rutina y guarda su estado
  void minimizeRoutine(Routine routine) {
    savedRoutineState = routine; // Guarda el estado actual de la rutina
    minimizedRoutine = routine;
    startRoutineTimer();
    notifyListeners();
  }

  // Restaura la rutina minimizada, detiene el temporizador y reinicia el tiempo
  void restoreRoutine() {
    minimizedRoutine = null;
    savedRoutineState = null;
    stopRoutineTimer(); // Detiene el temporizador
    // No reiniciamos minimizedRoutineDuration aquí para preservar el tiempo al restaurar
    notifyListeners();
  }

  // Cancela la rutina minimizada y limpia el estado
  void cancelMinimizedRoutine() {
    minimizedRoutine = null;
    savedRoutineState = null; // Limpia el estado guardado
    minimizedRoutineDuration = Duration.zero;
    stopRoutineTimer();
    notifyListeners();
  }

  Future<void> fetchExercises({int? muscleGroup, int? equipment, int page = 1}) async {
    _exercises = await _apiService.fetchExercises(muscleGroup: muscleGroup, equipment: equipment, page: page);
    notifyListeners();
  }

  Future<void> loadMuscleGroups() async {
    _muscleGroups = await _apiService.fetchMuscleGroups();
    notifyListeners();
  }

  Future<void> loadEquipment() async {
    _equipment = await _apiService.fetchEquipment();
    notifyListeners();
  }

  Future<void> _loadRoutines() async {
    if (_userId != null) {
      _routines = await _dbHelper.getRoutines(_userId!);
      print("Rutinas cargadas: ${_routines.length}");
      for (var routine in _routines) {
        print("Rutina: ${routine.name} con ${routine.exercises.length} ejercicios");
      }
      notifyListeners();
    }
  }

  Future<void> _loadCompletedRoutines() async {
    if (_userId != null) {
      _completedRoutines = await _dbHelper.getCompletedRoutines(_userId!);
      print("Rutinas completadas cargadas: ${_completedRoutines.length}");
      for (var completedRoutine in _completedRoutines) {
        print("Rutina completada: ${completedRoutine.name} con ${completedRoutine.exercises.length} ejercicios");
      }
      notifyListeners();
    }
  }

  Future<void> completeRoutine(Routine routine, Duration duration) async {
    int totalVolume = calculateTotalVolume(routine);
   print("Antes de completar la rutina, userId: $_userId");

    // Crear una copia de la rutina con un nuevo ID y marcarla como completada
    Routine completedRoutine = routine.copyWith(
      id: uuid.v4(),
      isCompleted: true,
      dateCompleted: DateTime.now(),
      duration: duration,
      totalVolume: totalVolume,
    );

    // Guardar la rutina completada en la base de datos
    await _dbHelper.insertRoutine(completedRoutine, _userId!);

    // Recargar rutinas completadas
    await _loadCompletedRoutines();

    print("Rutina completada: ${completedRoutine.name} con duración de ${duration.inMinutes} minutos y volumen total de $totalVolume kg");
    print("Después de completar la rutina, userId: $_userId");

  }

  Future<void> saveRoutine(Routine routine) async {
    if (_userId != null) {
      await _dbHelper.insertRoutine(routine, _userId!);
      _routines.add(routine);
      print("Rutina guardada: ${routine.name} con ${routine.exercises.length} ejercicios");
      notifyListeners();
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    if (_userId != null) {
      await _dbHelper.updateRoutine(routine, _userId!);
      final index = _routines.indexWhere((r) => r.id == routine.id);
      if (index != -1) {
        _routines[index] = routine;
        print("Rutina actualizada: ${routine.name} con ${routine.exercises.length} ejercicios");
        notifyListeners();
      }
    }
  }

  Future<void> addExerciseToRoutine(Exercise exercise, String routineId) async {
    await _dbHelper.insertExercise(exercise, routineId);
    final routine = _routines.firstWhere((routine) => routine.id == routineId);
    routine.exercises.add(exercise);
    print("Ejercicio añadido: ${exercise.name} a la rutina ID: $routineId");
    notifyListeners();
  }

  Future<void> addSeriesToExercise(Series series, String exerciseId) async {
    series.lastSavedPerceivedExertion = series.perceivedExertion;
    await _dbHelper.insertSeries(series, exerciseId);
    final exercise = _routines
        .expand((routine) => routine.exercises)
        .firstWhere((exercise) => exercise.id == exerciseId);
    exercise.series.add(series);
    print("Serie añadida a ejercicio ID: $exerciseId con peso ${series.weight} kg y ${series.reps} repeticiones");
    notifyListeners();
  }

  void updateRoutineDuration(String routineId, Duration duration) {
    final routine = _routines.firstWhere((routine) => routine.id == routineId);
    routine.duration = duration;
    print("Duración de rutina actualizada: ${routine.name} a ${duration.inMinutes} minutos");
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    await _dbHelper.deleteRoutine(id);
    _routines.removeWhere((routine) => routine.id == id);
    print("Rutina eliminada: ID $id");
    notifyListeners();
  }

  int calculateTotalVolume(Routine routine) {
    int totalVolume = 0;
    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalVolume += series.weight * series.reps;
      }
    }
    print("Volumen total calculado para rutina ${routine.name}: $totalVolume kg");
    return totalVolume;
  }
}
