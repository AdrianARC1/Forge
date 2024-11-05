import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercice_selection_screen.dart';
import '../app_state.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final Routine? routine;

  RoutineExecutionScreen({this.routine});

  @override
  _RoutineExecutionScreenState createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> {
  List<Exercise> exercises = [];
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
              previousWeight: series.weight,
              previousReps: series.reps,
              weight: 0,
              reps: 0,
              perceivedExertion: 0,
              lastSavedPerceivedExertion: series.perceivedExertion, // Para hint de RIR
              isCompleted: false,
            );
          }).toList(),
        );
      }).toList();
      routineName = widget.routine!.name;
    }

    // Ejecutar minimizeRoutine después de que el widget esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.minimizedRoutine == null) {
        appState.minimizeRoutine(widget.routine!); // Minimiza y comienza el temporizador
      }
    });
  }

  void _finishRoutine() {
    if (!_areAllSeriesCompleted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Completa todas las series para finalizar la rutina")),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.addCompletedRoutine(widget.routine!, appState.minimizedRoutineDuration);
    appState.restoreRoutine(); // Detiene el temporizador y limpia el estado de minimización
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

  void _minimizeRoutine() {
    Navigator.pop(context); // Regresa a la pantalla principal sin detener el temporizador
  }

  void _cancelExecution() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("¿Cancelar rutina?"),
          content: Text("¿Realmente quieres cancelar la rutina en ejecución?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.cancelMinimizedRoutine(); // Detiene el temporizador y limpia el estado
                Navigator.of(context).pop(); // Cierra el diálogo de confirmación
                Navigator.of(context).pop(); // Vuelve a la pantalla principal
              },
              child: Text("Sí"),
            ),
          ],
        );
      },
    );
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
          previousWeight: exercise.series.isNotEmpty ? exercise.series.last.weight : null,
          previousReps: exercise.series.isNotEmpty ? exercise.series.last.reps : null,
          weight: 0,
          reps: 0,
          perceivedExertion: 0,
          lastSavedPerceivedExertion: exercise.series.isNotEmpty
              ? exercise.series.last.perceivedExertion
              : null,
          isCompleted: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return WillPopScope(
      onWillPop: () async {
        _minimizeRoutine(); // Minimiza la rutina en lugar de cerrar la pantalla
        return false; // Evita que la pantalla se cierre
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(routineName),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _minimizeRoutine,
          ),
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
                'Tiempo Transcurrido: ${_formatDuration(appState.minimizedRoutineDuration)}',
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${seriesIndex + 1}"),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _autofillSeries(series);
                                        });
                                      },
                                      child: Text(
                                        "${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "${series.previousWeight ?? 'KG'}",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      controller: TextEditingController(
                                        text: series.weight > 0 ? series.weight.toString() : "",
                                      ),
                                      onChanged: (value) {
                                        series.weight = int.tryParse(value) ?? series.weight;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "${series.previousReps ?? 'Reps'}",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      controller: TextEditingController(
                                        text: series.reps > 0 ? series.reps.toString() : "",
                                      ),
                                      onChanged: (value) {
                                        series.reps = int.tryParse(value) ?? series.reps;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: series.lastSavedPerceivedExertion != null
                                            ? series.lastSavedPerceivedExertion.toString()
                                            : "RIR",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      controller: TextEditingController(
                                        text: series.perceivedExertion > 0
                                            ? series.perceivedExertion.toString()
                                            : "",
                                      ),
                                      onChanged: (value) {
                                        series.perceivedExertion = int.tryParse(value) ?? series.perceivedExertion;
                                      },
                                    ),
                                  ),
                                  Checkbox(
                                    value: series.isCompleted,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _autofillSeries(series);
                                        }
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
      ),
    );
  }

  void _autofillSeries(Series series) {
    setState(() {
      if (series.weight == 0 && series.previousWeight != null) {
        series.weight = series.previousWeight!;
      }
      if (series.reps == 0 && series.previousReps != null) {
        series.reps = series.previousReps!;
      }
      if (series.perceivedExertion == 0 && series.lastSavedPerceivedExertion != null) {
        series.perceivedExertion = series.lastSavedPerceivedExertion!;
      }
      series.isCompleted = true;
    });
  }
}
