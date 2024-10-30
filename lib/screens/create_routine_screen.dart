import 'package:flutter/material.dart';
import 'exercice_selection_screen.dart';

class CreateRoutineScreen extends StatefulWidget {
  @override
  _CreateRoutineScreenState createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  List<Map<String, dynamic>> selectedExercises = []; // Lista de ejercicios seleccionados para la rutina

  // Función para abrir la pantalla de selección de ejercicios
  Future<void> _addExercise() async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExerciseSelectionScreen()),
    );

    // Si el usuario selecciona un ejercicio, añadirlo a la lista de ejercicios de la rutina
    if (selectedExercise != null) {
      setState(() {
        selectedExercises.add(selectedExercise);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Rutina"),
      ),
      body: Column(
        children: [
          // Mostrar la lista de ejercicios seleccionados
          Expanded(
            child: ListView.builder(
              itemCount: selectedExercises.length,
              itemBuilder: (context, index) {
                final exercise = selectedExercises[index];
                return ListTile(
                  title: Text(exercise['name']),
                  subtitle: Text("Músculo: ${exercise['category']}"),
                );
              },
            ),
          ),
          // Botón para añadir ejercicio
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _addExercise,
              child: Text("Añadir Ejercicio"),
            ),
          ),
        ],
      ),
    );
  }
}
