// lib/screens/exercise_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({Key? key}) : super(key: key);

  @override
  _ExerciseSelectionScreenState createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  String searchQuery = "";
  String? selectedMuscleGroup;
  String? selectedEquipment;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    appState.fetchAllExercises();
    appState.loadMuscleGroups();
    appState.loadEquipment();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Cargar más ejercicios al acercarse al final
      Provider.of<AppState>(context, listen: false).loadMoreExercises();
    }
  }

  void _filterExercises() async {
    setState(() {
      _isLoading = true;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    appState.applyFilters(
      muscleGroup: selectedMuscleGroup,
      equipment: selectedEquipment,
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Seleccionar Ejercicio"),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              Navigator.pop(context); // Cierra la pantalla sin seleccionar
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar ejercicio',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
                appState.filterExercises(query);
              },
            ),
          ),
          // Filtros de músculo y equipo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Filtro de músculo
              DropdownButton<String>(
                hint: Text("Músculo"),
                value: selectedMuscleGroup,
                onChanged: (value) {
                  setState(() {
                    selectedMuscleGroup = value;
                    selectedEquipment = null; // Reiniciamos el filtro de equipo
                    searchQuery = ""; // Reiniciamos la búsqueda
                  });
                  _filterExercises();
                },
                items: appState.muscleGroups.map<DropdownMenuItem<String>>((group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
              ),
              // Filtro de equipo
              DropdownButton<String>(
                hint: Text("Equipo"),
                value: selectedEquipment,
                onChanged: (value) {
                  setState(() {
                    selectedEquipment = value;
                    selectedMuscleGroup = null; // Reiniciamos el filtro de músculo
                    searchQuery = ""; // Reiniciamos la búsqueda
                  });
                  _filterExercises();
                },
                items: appState.equipment.map<DropdownMenuItem<String>>((equip) {
                  return DropdownMenuItem<String>(
                    value: equip,
                    child: Text(equip),
                  );
                }).toList(),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: appState.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = appState.exercises[index];
                      final exerciseName = exercise['name'] as String;

                      return ListTile(
                        leading: exercise['gifUrl'] != null
                            ? Image.network(
                                exercise['gifUrl'],
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.image_not_supported);
                                },
                              )
                            : Icon(Icons.image_not_supported),
                        title: Text(exerciseName),
                        subtitle: Text(
                            'Músculo: ${exercise['target']}\nEquipo: ${exercise['equipment']}'),
                        onTap: () {
                          Navigator.pop(context, exercise); // Devuelve el ejercicio seleccionado
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
