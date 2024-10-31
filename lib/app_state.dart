import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'api/wger_api_service.dart';

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
  final String id;
  final String name;
  List<Series> series;

  Exercise({required this.id, required this.name, this.series = const []});
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

  // Método para copiar una rutina con cambios
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
  List<Map<String, dynamic>> _completedRoutines = []; // Rutinas completadas
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _muscleGroups = [];
  List<Map<String, dynamic>> _equipment = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WgerApiService _apiService = WgerApiService();

  List<Routine> get routines => _routines;
  List<Map<String, dynamic>> get completedRoutines => _completedRoutines;
  List<Map<String, dynamic>> get exercises => _exercises;
  List<Map<String, dynamic>> get muscleGroups => _muscleGroups;
  List<Map<String, dynamic>> get equipment => _equipment;

  AppState() {
    _loadRoutines();
    _loadCompletedRoutines(); // Carga las rutinas completadas al inicio
    loadMuscleGroups();
    loadEquipment();
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

  // Cargar rutinas desde la base de datos al iniciar la app
  Future<void> _loadRoutines() async {
    _routines = await _dbHelper.getRoutines();
    notifyListeners();
  }

  // Cargar rutinas completadas en el historial
  Future<void> _loadCompletedRoutines() async {
    _completedRoutines = await _dbHelper.getCompletedRoutines();
    notifyListeners();
  }

  // Añadir una rutina finalizada al historial
  Future<void> addCompletedRoutine(Routine routine, Duration duration) async {
    await _dbHelper.insertCompletedRoutine(routine, duration);
    await _loadCompletedRoutines(); // Recarga el historial después de añadir
  }

  // Guardar rutina en la base de datos y en la lista de rutinas
  Future<void> saveRoutine(Routine routine) async {
    await _dbHelper.insertRoutine(routine);
    _routines.add(routine);
    notifyListeners();
  }

  // Actualizar una rutina existente
  Future<void> updateRoutine(Routine routine) async {
    await _dbHelper.updateRoutine(routine);
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      notifyListeners();
    }
  }

  // Añadir un ejercicio a la base de datos y a la rutina
  Future<void> addExerciseToRoutine(Exercise exercise, String routineId) async {
    await _dbHelper.insertExercise(exercise, routineId);
    final routine = _routines.firstWhere((routine) => routine.id == routineId);
    routine.exercises.add(exercise);
    notifyListeners();
  }

  // Añadir una serie a la base de datos y al ejercicio
  Future<void> addSeriesToExercise(Series series, String exerciseId) async {
    series.lastSavedPerceivedExertion = series.perceivedExertion;
    await _dbHelper.insertSeries(series, exerciseId);
    final exercise = _routines
        .expand((routine) => routine.exercises)
        .firstWhere((exercise) => exercise.id == exerciseId);
    exercise.series.add(series);
    notifyListeners();
  }

  // Actualizar duración de la rutina
  void updateRoutineDuration(String routineId, Duration duration) {
    final routine = _routines.firstWhere((routine) => routine.id == routineId);
    routine.duration = duration;
    notifyListeners();
  }

  // Eliminar una rutina de la lista y base de datos
  Future<void> deleteRoutine(String id) async {
    await _dbHelper.deleteRoutine(id);
    _routines.removeWhere((routine) => routine.id == id);
    notifyListeners();
  }
}
