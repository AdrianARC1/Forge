import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'api/wger_api_service.dart';

class Series {
  int? previousWeight;
  int? previousReps;
  int? lastSavedWeight; // Para almacenar el último peso guardado
  int? lastSavedReps; // Para almacenar las últimas repeticiones guardadas
  int weight;
  int reps;
  int perceivedExertion; // 1 a 10
  bool isCompleted;

  Series({
    this.previousWeight,
    this.previousReps,
    this.lastSavedWeight,
    this.lastSavedReps,
    required this.weight,
    required this.reps,
    required this.perceivedExertion,
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

  Routine({
    required this.id,
    required this.name,
    required this.dateCreated,
    this.exercises = const [],
  });
}

class AppState with ChangeNotifier {
  List<Routine> _routines = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _muscleGroups = [];
  List<Map<String, dynamic>> _equipment = [];
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WgerApiService _apiService = WgerApiService();

  List<Routine> get routines => _routines;
  List<Map<String, dynamic>> get exercises => _exercises;
  List<Map<String, dynamic>> get muscleGroups => _muscleGroups;
  List<Map<String, dynamic>> get equipment => _equipment;

  AppState() {
    _loadRoutines();
    loadMuscleGroups();
    loadEquipment();
  }

  Future<void> fetchExercises({int? muscleGroup, int? equipment}) async {
    _exercises = await _apiService.fetchExercises(muscleGroup: muscleGroup, equipment: equipment);
    notifyListeners();
  }

  // Cargar categorías de músculos desde la API
  Future<void> loadMuscleGroups() async {
    _muscleGroups = await _apiService.fetchMuscleGroups();
    notifyListeners();
  }

  // Cargar tipos de equipamiento desde la API
  Future<void> loadEquipment() async {
    _equipment = await _apiService.fetchEquipment();
    notifyListeners();
  }

  // Cargar las rutinas desde la base de datos al iniciar la app
  Future<void> _loadRoutines() async {
    _routines = await _dbHelper.getRoutines();
    notifyListeners();
  }

  // Añadir una rutina a la lista y base de datos
  void addRoutine(Routine routine) async {
    _routines.add(routine);
    await _dbHelper.insertRoutine(routine);
    notifyListeners();
  }

  // Añadir un ejercicio a una rutina
  void addExerciseToRoutine(String routineId, Exercise exercise) {
    final routine = _routines.firstWhere((routine) => routine.id == routineId);
    routine.exercises.add(exercise);
    notifyListeners();
  }

  // Añadir una serie a un ejercicio específico en una rutina
  void addSeriesToExercise(String routineId, String exerciseId, Series series) {
    final routine = _routines.firstWhere((routine) => routine.id == routineId);
    final exercise = routine.exercises.firstWhere((exercise) => exercise.id == exerciseId);
    exercise.series.add(series);
    notifyListeners();
  }

  // Eliminar una rutina de la lista y base de datos
  void deleteRoutine(String id) async {
    _routines.removeWhere((routine) => routine.id == id);
    await _dbHelper.deleteRoutine(id);
    notifyListeners();
  }
}
