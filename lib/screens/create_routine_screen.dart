import 'package:flutter/material.dart';
import 'exercice_selection_screen.dart';
import '../app_state.dart';

class CreateRoutineScreen extends StatefulWidget {
  @override
  _CreateRoutineScreenState createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  List<Exercise> selectedExercises = []; // Lista de ejercicios seleccionados para la rutina

  // Función para abrir la pantalla de selección de ejercicios
  Future<void> _addExercise() async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExerciseSelectionScreen()),
    );

    if (selectedExercise != null) {
      setState(() {
        final exercise = Exercise(
          id: selectedExercise['id'].toString(),
          name: selectedExercise['name'],
          series: [],
        );
        selectedExercises.add(exercise);
      });
    }
  }

  // Añadir una nueva serie al ejercicio
  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      final newSeries = Series(
        previousWeight: exercise.series.isNotEmpty ? exercise.series.last.lastSavedWeight : null,
        previousReps: exercise.series.isNotEmpty ? exercise.series.last.lastSavedReps : null,
        weight: 0,
        reps: 0,
        perceivedExertion: 0,
        isCompleted: false,
      );

      exercise.series.add(newSeries);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Rutina"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: selectedExercises.length,
              itemBuilder: (context, index) {
                final exercise = selectedExercises[index];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(exercise.name),
                      subtitle: Text("Series: ${exercise.series.length}"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("SERIE"),
                          Text("ANTERIOR"),
                          Text("KG"),
                          Text("REPS"),
                          Text("RIR"),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: exercise.series.length,
                      itemBuilder: (context, seriesIndex) {
                        final series = exercise.series[seriesIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${seriesIndex + 1}"),
                              Text("${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}"),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(hintText: "KG"),
                                  onChanged: (value) {
                                    setState(() {
                                      series.weight = int.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(hintText: "Reps"),
                                  onChanged: (value) {
                                    setState(() {
                                      series.reps = int.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(hintText: "RIR"),
                                  onChanged: (value) {
                                    setState(() {
                                      series.perceivedExertion = int.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              Checkbox(
                                value: series.isCompleted,
                                onChanged: (value) {
                                  setState(() {
                                    series.isCompleted = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: () => _addSeriesToExercise(exercise),
                        child: Text("+ Agregar Serie"),
                      ),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _addExercise,
              child: Text("Añadir Ejercicio"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Aquí iría la lógica para guardar la rutina completa y actualizar los datos de "Anterior"
              },
              child: Text("Guardar Rutina"),
            ),
          ),
        ],
      ),
    );
  }
}
