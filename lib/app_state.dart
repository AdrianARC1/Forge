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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WgerApiService _apiService = WgerApiService();

  List<Routine> get routines => _routines;
  List<Map<String, dynamic>> get exercises => _exercises;

  AppState() {
    _loadRoutines();
  }

  Future<void> fetchExercises({int? muscleGroup, int? equipment}) async {
    _exercises = await _apiService.fetchExercises(muscleGroup: muscleGroup, equipment: equipment);
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
