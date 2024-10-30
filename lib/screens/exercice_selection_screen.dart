import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  _ExerciseSelectionScreenState createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  String searchQuery = "";
  int? selectedMuscleGroup;
  int? selectedEquipment;

  @override
  void initState() {
    super.initState();
    // Cargar ejercicios desde la API al iniciar la pantalla
    Provider.of<AppState>(context, listen: false).fetchExercises();
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
  hint: Text("Seleccionar músculo"),
  value: selectedMuscleGroup,
  onChanged: (value) {
    setState(() {
      selectedMuscleGroup = value;
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
  hint: Text("Seleccionar equipo"),
  value: selectedEquipment,
  onChanged: (value) {
    setState(() {
      selectedEquipment = value;
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
              itemCount: appState.exercises.length,
              itemBuilder: (context, index) {
                final exercise = appState.exercises[index];
                final exerciseName = exercise['name'].toLowerCase();
                
                // Filtra los ejercicios según el término de búsqueda
                if (!exerciseName.contains(searchQuery)) return Container();

                return ListTile(
                  title: Text(exercise['name']),
                  subtitle: Text("Músculo: ${exercise['category']}, Equipo: ${exercise['equipment']}"),
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
