import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'api/wger_api_service.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Series {
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
  List<Exercise> exercises;
  Duration duration;

  Routine({
    required this.id,
    required this.name,
    required this.dateCreated,
    this.exercises = const [],
    this.duration = Duration.zero,
  });

  Routine copyWith({
    String? name,
    List<Exercise>? exercises,
    Duration? duration,
  }) {
    return Routine(
      id: this.id,
      name: name ?? this.name,
      dateCreated: this.dateCreated,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
    );
  }
}

class AppState with ChangeNotifier {
  List<Routine> _routines = [];
  List<Map<String, dynamic>> _completedRoutines = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _muscleGroups = [];
  List<Map<String, dynamic>> _equipment = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WgerApiService _apiService = WgerApiService();

  Routine? minimizedRoutine;
  Routine? savedRoutineState; // Guarda el estado de la rutina minimizada
  Duration minimizedRoutineDuration = Duration.zero;
  Timer? _timer;

  List<Routine> get routines => _routines;
  List<Map<String, dynamic>> get completedRoutines => _completedRoutines;
  List<Map<String, dynamic>> get exercises => _exercises;
  List<Map<String, dynamic>> get muscleGroups => _muscleGroups;
  List<Map<String, dynamic>> get equipment => _equipment;

  AppState() {
    _loadRoutines();
    _loadCompletedRoutines();
    loadMuscleGroups();
    loadEquipment();
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

  Future<void> fetchExercises({int? muscleGroup, int? equipment}) async {
    _exercises = await _apiService.fetchExercises(muscleGroup: muscleGroup, equipment: equipment);
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
    _routines = await _dbHelper.getRoutines();
    print("Rutinas cargadas: ${_routines.length}");
    for (var routine in _routines) {
      print("Rutina: ${routine.name} con ${routine.exercises.length} ejercicios");
    }
    notifyListeners();
  }

  Future<void> _loadCompletedRoutines() async {
    _completedRoutines = await _dbHelper.getCompletedRoutines();
    print("Rutinas completadas cargadas: ${_completedRoutines.length}");
    for (var completedRoutine in _completedRoutines) {
      print("Rutina completada: ${completedRoutine['name']} con ${(completedRoutine['exercises'] as List).length} ejercicios");
    }
    notifyListeners();
  }

  Future<void> addCompletedRoutine(Routine routine, Duration duration) async {
    int totalVolume = calculateTotalVolume(routine);
    await _dbHelper.insertCompletedRoutine(routine, duration, totalVolume);

    // Recargar rutinas completadas para actualizar la vista
    await _loadCompletedRoutines();
    print("Rutina completada añadida: ${routine.name} con duración de ${duration.inMinutes} minutos y volumen total de $totalVolume kg");
  }

  Future<void> saveRoutine(Routine routine) async {
    await _dbHelper.insertRoutine(routine);
    _routines.add(routine);
    print("Rutina guardada: ${routine.name} con ${routine.exercises.length} ejercicios");
    notifyListeners();
  }

  Future<void> updateRoutine(Routine routine) async {
    await _dbHelper.updateRoutine(routine);
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      print("Rutina actualizada: ${routine.name} con ${routine.exercises.length} ejercicios");
      notifyListeners();
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
