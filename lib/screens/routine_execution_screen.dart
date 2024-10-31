import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercice_selection_screen.dart';
import '../app_state.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final Routine? routine; // Cambiado a opcional

  RoutineExecutionScreen({this.routine}); // Constructor actualizado

  @override
  _RoutineExecutionScreenState createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> {
  List<Exercise> exercises = [];
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  String routineName = "Entrenamiento Vacío";

  @override
  void initState() {
    super.initState();
    
    if (widget.routine != null) {
      exercises = widget.routine!.exercises.map((exercise) {
        return Exercise(
          id: exercise.id,
          name: exercise.name,
          series: exercise.series.map((series) {
            return Series(
              previousWeight: series.previousWeight,
              previousReps: series.previousReps,
              weight: series.weight,
              reps: series.reps,
              perceivedExertion: series.perceivedExertion,
              isCompleted: false,
            );
          }).toList(),
        );
      }).toList();
      routineName = widget.routine!.name;
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el temporizador cuando se salga de la pantalla
    super.dispose();
  }

void _finishRoutine() {
  if (!_areAllSeriesCompleted()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Completa todas las series para finalizar la rutina")),
    );
    return;
  }

  final appState = Provider.of<AppState>(context, listen: false);

  if (widget.routine != null) {
    widget.routine!.exercises = exercises;
    widget.routine!.duration = _elapsedTime;
    appState.saveRoutine(widget.routine!); // Guardar en historial solo al finalizar
  }

  Navigator.pop(context);
}


  bool _areAllSeriesCompleted() {
    for (var exercise in exercises) {
      for (var series in exercise.series) {
        if (!series.isCompleted) return false;
      }
    }
    return true;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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

  void _deleteSeries(Exercise exercise, int seriesIndex) {
    setState(() {
      exercise.series.removeAt(seriesIndex);
    });
  }

  void _cancelExecution() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routineName),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: _cancelExecution,
            tooltip: 'Cancelar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Tiempo Transcurrido: ${_formatDuration(_elapsedTime)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
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
                          return Dismissible(
                            key: UniqueKey(),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) => _deleteSeries(exercise, seriesIndex),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${seriesIndex + 1}"),
                                  GestureDetector(
                                    onTap: () {
                                      if (series.previousWeight != null &&
                                          series.previousReps != null) {
                                        setState(() {
                                          series.weight = series.previousWeight!;
                                          series.reps = series.previousReps!;
                                        });
                                      }
                                    },
                                    child: Text(
                                      "${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: series.weight > 0 ? series.weight.toString() : "",
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "${series.previousWeight ?? "KG"}",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        series.weight = int.tryParse(value) ?? series.weight;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: series.reps > 0 ? series.reps.toString() : "",
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "${series.previousReps ?? "Reps"}",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        series.reps = int.tryParse(value) ?? series.reps;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: series.perceivedExertion > 0
                                            ? series.perceivedExertion.toString()
                                            : "",
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "RIR",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        series.perceivedExertion =
                                            int.tryParse(value) ?? series.perceivedExertion;
                                      },
                                    ),
                                  ),
                                  Checkbox(
                                    value: series.isCompleted,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true &&
                                            (series.weight == 0 || series.reps == 0)) {
                                          series.weight = series.previousWeight ?? 0;
                                          series.reps = series.previousReps ?? 0;
                                        }
                                        series.isCompleted = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
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
          ),
        ],
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
