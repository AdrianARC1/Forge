import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercice_selection_screen.dart';
import '../app_state.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final Routine routine;

  RoutineExecutionScreen({required this.routine});

  @override
  _RoutineExecutionScreenState createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> {
  List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
    exercises = List.from(widget.routine.exercises);
  }

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
        exercises.add(exercise);
      });
    }
  }

  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      exercise.series.add(
        Series(
          previousWeight: exercise.series.isNotEmpty ? exercise.series.last.lastSavedWeight : null,
          previousReps: exercise.series.isNotEmpty ? exercise.series.last.lastSavedReps : null,
          weight: 0,
          reps: 0,
          perceivedExertion: 0,
          isCompleted: false,
        ),
      );
    });
  }

  bool _areAllSeriesCompleted() {
    for (var exercise in exercises) {
      for (var series in exercise.series) {
        if (!series.isCompleted) return false;
      }
    }
    return true;
  }

  void _finishRoutine() {
    if (!_areAllSeriesCompleted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Completa todas las series para finalizar la rutina")),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    widget.routine.exercises = exercises;
    appState.saveRoutine(widget.routine);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: exercises.map((exercise) {
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
                          GestureDetector(
                            onTap: () {
                              if (series.previousWeight != null && series.previousReps != null) {
                                setState(() {
                                  series.weight = series.previousWeight!;
                                  series.reps = series.previousReps!;
                                });
                              }
                            },
                            child: Text(
                              "${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "${series.weight}",
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  series.weight = int.tryParse(value) ?? series.weight;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "${series.reps}",
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  series.reps = int.tryParse(value) ?? series.reps;
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
                                  series.perceivedExertion = int.tryParse(value) ?? series.perceivedExertion;
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _addExercise,
            child: Text("Añadir Ejercicio"),
          ),
          SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _finishRoutine,
            label: Text("Finalizar Rutina"),
            icon: Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}
