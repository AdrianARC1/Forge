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
  Duration displayDuration = Duration.zero;
  Timer? _localTimer;

  // Mapas para mantener los controladores de cada Serie
  Map<Series, TextEditingController> weightControllers = {};
  Map<Series, TextEditingController> repsControllers = {};
  Map<Series, TextEditingController> exertionControllers = {};

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.savedRoutineState != null) {
      // Restaurando rutina minimizada
      exercises = appState.savedRoutineState!.exercises;
      routineName = appState.savedRoutineState!.name;
      displayDuration = appState.minimizedRoutineDuration;
    } else if (widget.routine != null) {
      // Iniciando nueva rutina
      exercises = widget.routine!.exercises.map((exercise) {
        return Exercise(
          id: exercise.id,
          name: exercise.name,
          series: exercise.series.map((series) {
            return Series(
              previousWeight: series.weight,
              previousReps: series.reps,
              weight: 0, // Iniciamos en 0
              reps: 0,   // Iniciamos en 0
              perceivedExertion: 0, // Iniciamos en 0
              lastSavedPerceivedExertion: series.perceivedExertion,
              isCompleted: false,
            );
          }).toList(),
        );
      }).toList();
      routineName = widget.routine!.name;
      displayDuration = Duration.zero; // Comenzamos desde cero
    }

    // Inicializar controladores
    for (var exercise in exercises) {
      for (var series in exercise.series) {
        if (appState.savedRoutineState != null) {
          // Restaurando rutina minimizada: inicializamos los controladores con los valores ingresados
          weightControllers[series] = TextEditingController(
            text: series.weight > 0 ? series.weight.toString() : '',
          );
          repsControllers[series] = TextEditingController(
            text: series.reps > 0 ? series.reps.toString() : '',
          );
          exertionControllers[series] = TextEditingController(
            text: series.perceivedExertion > 0 ? series.perceivedExertion.toString() : '',
          );
        } else {
          // Nueva rutina: inicializamos los controladores sin texto
          weightControllers[series] = TextEditingController();
          repsControllers[series] = TextEditingController();
          exertionControllers[series] = TextEditingController();
        }
      }
    }

    _startLocalTimer();
  }

  @override
  void dispose() {
    // Liberar todos los controladores
    weightControllers.values.forEach((controller) => controller.dispose());
    repsControllers.values.forEach((controller) => controller.dispose());
    exertionControllers.values.forEach((controller) => controller.dispose());
    _localTimer?.cancel();
    super.dispose();
  }

  void _startLocalTimer() {
    if (_localTimer == null || !_localTimer!.isActive) {
      _localTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          displayDuration += Duration(seconds: 1);
          final appState = Provider.of<AppState>(context, listen: false);
          appState.minimizedRoutineDuration = displayDuration;
        });
      });
    }
  }

  void _finishRoutine() {
    if (!_areAllSeriesCompleted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Completa todas las series para finalizar la rutina")),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    // Actualizar la rutina con los ejercicios y series actuales
    Routine completedRoutine = Routine(
      id: widget.routine!.id,
      name: routineName,
      dateCreated: widget.routine!.dateCreated,
      exercises: exercises,
      duration: displayDuration,
    );
    appState.addCompletedRoutine(completedRoutine, appState.minimizedRoutineDuration);
    appState.restoreRoutine();
    appState.minimizedRoutineDuration = Duration.zero; // Reiniciar duración
    _localTimer?.cancel(); // Detener el temporizador local
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
    final appState = Provider.of<AppState>(context, listen: false);
    appState.minimizeRoutine(
      Routine(
        id: widget.routine!.id,
        name: routineName,
        dateCreated: widget.routine!.dateCreated,
        exercises: exercises,
        duration: displayDuration,
      ),
    );
    _localTimer?.cancel();
    Navigator.pop(context);
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
                appState.cancelMinimizedRoutine();
                _localTimer?.cancel();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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

        // Inicializar controladores sin texto
        for (var series in exercise.series) {
          weightControllers[series] = TextEditingController();
          repsControllers[series] = TextEditingController();
          exertionControllers[series] = TextEditingController();
        }
      });
    }
  }

  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      Series newSeries = Series(
        previousWeight: exercise.series.isNotEmpty ? exercise.series.last.weight : null,
        previousReps: exercise.series.isNotEmpty ? exercise.series.last.reps : null,
        weight: 0,
        reps: 0,
        perceivedExertion: 0,
        lastSavedPerceivedExertion: exercise.series.isNotEmpty
            ? exercise.series.last.perceivedExertion
            : null,
        isCompleted: false,
      );
      exercise.series.add(newSeries);

      // Inicializar controladores sin texto
      weightControllers[newSeries] = TextEditingController();
      repsControllers[newSeries] = TextEditingController();
      exertionControllers[newSeries] = TextEditingController();
    });
  }

  void _autofillSeries(Series series) {
    setState(() {
      if (series.weight == 0 && series.previousWeight != null) {
        series.weight = series.previousWeight!;
        weightControllers[series]?.text = series.weight.toString();
      }
      if (series.reps == 0 && series.previousReps != null) {
        series.reps = series.previousReps!;
        repsControllers[series]?.text = series.reps.toString();
      }
      if (series.perceivedExertion == 0 && series.lastSavedPerceivedExertion != null) {
        series.perceivedExertion = series.lastSavedPerceivedExertion!;
        exertionControllers[series]?.text = series.perceivedExertion.toString();
      }
      series.isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _minimizeRoutine();
        return false;
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
                'Tiempo Transcurrido: ${_formatDuration(displayDuration)}',
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
                                      _autofillSeries(series);
                                    },
                                    child: Text(
                                      "${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: weightControllers[series],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: series.previousWeight != null
                                            ? series.previousWeight.toString()
                                            : 'KG',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        series.weight = int.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: repsControllers[series],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: series.previousReps != null
                                            ? series.previousReps.toString()
                                            : 'Reps',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        series.reps = int.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: exertionControllers[series],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: series.lastSavedPerceivedExertion != null
                                            ? series.lastSavedPerceivedExertion.toString()
                                            : 'RIR',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onChanged: (value) {
                                        series.perceivedExertion = int.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  Checkbox(
                                    value: series.isCompleted,
                                    onChanged: (value) {
                                      if (value == true) {
                                        _autofillSeries(series);
                                      }
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
}
