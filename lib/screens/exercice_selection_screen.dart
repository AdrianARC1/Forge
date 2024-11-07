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
  int? selectedMuscleGroup;
  int? selectedEquipment;
  ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    appState.fetchExercises();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final thresholdReached = _scrollController.position.extentAfter < 200;
    if (thresholdReached) {
      _loadMoreExercises();
    }
  }

  Future<void> _loadMoreExercises() async {
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.fetchExercises(
      muscleGroup: selectedMuscleGroup,
      equipment: selectedEquipment,
      page: _currentPage,
    );
    setState(() {
      _isLoadingMore = false;
    });
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
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          // Filtros de músculo y equipo dinámicos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Para el filtro de músculo
              DropdownButton<int>(
                hint: Text("Músculo"),
                value: selectedMuscleGroup,
                onChanged: (value) {
                  setState(() {
                    selectedMuscleGroup = value;
                    _currentPage = 1; // Reiniciar paginación
                  });
                  appState.fetchExercises(muscleGroup: value, equipment: selectedEquipment);
                },
                items: appState.muscleGroups.map<DropdownMenuItem<int>>((group) {
                  return DropdownMenuItem<int>(
                    value: group['id'] as int,
                    child: Text(group['name']),
                  );
                }).toList(),
              ),

              // Para el filtro de equipo
              DropdownButton<int>(
                hint: Text("Equipo"),
                value: selectedEquipment,
                onChanged: (value) {
                  setState(() {
                    selectedEquipment = value;
                    _currentPage = 1; // Reiniciar paginación
                  });
                  appState.fetchExercises(muscleGroup: selectedMuscleGroup, equipment: value);
                },
                items: appState.equipment.map<DropdownMenuItem<int>>((equip) {
                  return DropdownMenuItem<int>(
                    value: equip['id'] as int,
                    child: Text(equip['name']),
                  );
                }).toList(),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: appState.exercises.length + 1,
              itemBuilder: (context, index) {
                if (index == appState.exercises.length) {
                  return _isLoadingMore
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox();
                }

                final exercise = appState.exercises[index];
                final exerciseName = exercise['name'].toLowerCase();

                // Filtra los ejercicios según el término de búsqueda
                if (!exerciseName.contains(searchQuery)) return Container();

                return ListTile(
                  leading: exercise['image'] != null
                      ? Image.network(exercise['image'], width: 50, height: 50)
                      : Icon(Icons.image_not_supported),
                  title: Text(exercise['name']),
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
