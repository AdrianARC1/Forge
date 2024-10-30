import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';

class Routine {
  final String id;
  final String name;
  final DateTime dateCreated;

  Routine({required this.id, required this.name, required this.dateCreated});
}

class AppState with ChangeNotifier {
  List<Routine> _routines = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Routine> get routines => _routines;

  AppState() {
    _loadRoutines();
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
