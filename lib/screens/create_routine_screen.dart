import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercice_selection_screen.dart';
import '../app_state.dart';

class CreateRoutineScreen extends StatefulWidget {
  @override
  _CreateRoutineScreenState createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  List<Exercise> selectedExercises = [];

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
          series: [
            Series(
              previousWeight: null,
              previousReps: null,
              weight: 0,
              reps: 0,
              perceivedExertion: 0,
              isCompleted: false,
            ),
          ],
        );
        selectedExercises.add(exercise);
      });
    }
  }

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

  void _deleteSeries(Exercise exercise, int seriesIndex) {
    setState(() {
      exercise.series.removeAt(seriesIndex);
    });
  }

bool _areAllSeriesCompleted() {
  for (var exercise in selectedExercises) {
    for (var series in exercise.series) {
      if (!series.isCompleted) {
        return false;
      }
    }
  }
  return true;
}

void _saveRoutine() async {
  if (!_areAllSeriesCompleted()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Completa todas las series antes de guardar")),
    );
    return;
  }

  final routineName = _routineNameController.text.trim();
  if (routineName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Por favor, ingresa un nombre para la rutina")),
    );
    return;
  }

  final newRoutine = Routine(
    id: DateTime.now().toString(),
    name: routineName,
    dateCreated: DateTime.now(),
    exercises: selectedExercises,
  );

  final appState = Provider.of<AppState>(context, listen: false);
  await appState.saveRoutine(newRoutine);

  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Rutina"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _routineNameController,
                decoration: InputDecoration(
                  labelText: "Nombre de la Rutina",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Column(
              children: selectedExercises.map((exercise) {
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
                    Column(
                      children: exercise.series.map((series) {
                        int seriesIndex = exercise.series.indexOf(series);
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
                      }).toList(),
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
              }).toList(),
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
                onPressed: _saveRoutine,
                child: Text("Guardar Rutina"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
