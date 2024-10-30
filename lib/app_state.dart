import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'api/wger_api_service.dart';

class Routine {
  final String id;
  final String name;
  final DateTime dateCreated;

  Routine({required this.id, required this.name, required this.dateCreated});
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

  // Eliminar una rutina de la lista y base de datos
  void deleteRoutine(String id) async {
    _routines.removeWhere((routine) => routine.id == id);
    await _dbHelper.deleteRoutine(id);
    notifyListeners();
  }
}
