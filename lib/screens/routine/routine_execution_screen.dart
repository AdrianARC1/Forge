import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forge/screens/exercice_selection_screen.dart';
import 'package:forge/screens/navigation/main_navigation_screen.dart';
import 'package:forge/screens/routine/routine_summary_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'package:uuid/uuid.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final Routine? routine;

  RoutineExecutionScreen({this.routine});

  @override
  _RoutineExecutionScreenState createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> {
  List<Exercise> exercises = [];
  List<Exercise> originalExercises = [];
  String routineName = "Entrenamiento Vacío";
  ValueNotifier<Duration> _displayDuration = ValueNotifier(Duration.zero);
  Timer? _localTimer;

  Map<String, TextEditingController> weightControllers = {};
  Map<String, TextEditingController> repsControllers = {};
  Map<String, TextEditingController> exertionControllers = {};

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.savedRoutineState != null) {
      // Restaurando rutina minimizada
      exercises = appState.savedRoutineState!.exercises;
      routineName = appState.savedRoutineState!.name;
      _displayDuration.value = appState.minimizedRoutineDuration;
    } else if (widget.routine != null) {
      // Iniciando nueva rutina
      exercises = widget.routine!.exercises.map((exercise) {
        return Exercise(
          id: exercise.id,
          name: exercise.name,
          series: exercise.series.map((series) {
            return Series(
              id: Uuid().v4(),
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
      _displayDuration.value = Duration.zero; // Comenzamos desde cero
    }

    // Realizar una copia profunda de los ejercicios originales
    originalExercises = exercises.map((exercise) {
      return Exercise(
        id: exercise.id,
        name: exercise.name,
        series: exercise.series.map((series) {
          return Series(
            id: series.id,
            previousWeight: series.previousWeight,
            previousReps: series.previousReps,
            weight: series.weight,
            reps: series.reps,
            perceivedExertion: series.perceivedExertion,
            lastSavedPerceivedExertion: series.lastSavedPerceivedExertion,
            isCompleted: series.isCompleted,
          );
        }).toList(),
      );
    }).toList();

    // Inicializar controladores
    for (var exercise in exercises) {
      for (var series in exercise.series) {
        if (appState.savedRoutineState != null) {
          // Restaurando rutina minimizada: inicializamos los controladores con los valores ingresados
          weightControllers[series.id] = TextEditingController(
            text: series.weight > 0 ? series.weight.toString() : '',
          );
          repsControllers[series.id] = TextEditingController(
            text: series.reps > 0 ? series.reps.toString() : '',
          );
          exertionControllers[series.id] = TextEditingController(
            text: series.perceivedExertion > 0 ? series.perceivedExertion.toString() : '',
          );
        } else {
          // Nueva rutina: inicializamos los controladores sin texto
          weightControllers[series.id] = TextEditingController();
          repsControllers[series.id] = TextEditingController();
          exertionControllers[series.id] = TextEditingController();
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
    _displayDuration.dispose(); // Asegurarse de liberar el ValueNotifier
    super.dispose();
  }

  void _startLocalTimer() {
    if (_localTimer == null || !_localTimer!.isActive) {
      _localTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _displayDuration.value += Duration(seconds: 1);
        final appState = Provider.of<AppState>(context, listen: false);
        appState.minimizedRoutineDuration = _displayDuration.value;
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

    // Pausar el temporizador
    _localTimer?.cancel();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineSummaryScreen(
          routine: Routine(
            id: widget.routine?.id ?? '',
            name: routineName,
            dateCreated: widget.routine?.dateCreated ?? DateTime.now(),
            exercises: exercises,
            duration: _displayDuration.value,
          ),
          duration: _displayDuration.value,
          onDiscard: _discardRoutine,
          onResume: _resumeRoutine,
          onSave: _saveRoutine,
        ),
      ),
    );
  }

  void _discardRoutine() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.cancelMinimizedRoutine();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _resumeRoutine() {
    _startLocalTimer();
    Navigator.of(context).pop();
  }

  void _saveRoutine() {
    final appState = Provider.of<AppState>(context, listen: false);

    // Verificar si hay cambios en la rutina
    bool routineChanged = _hasRoutineChanged();

    if (routineChanged) {
      // Mostrar diálogo para actualizar la rutina
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Actualizar Rutina"),
            content: Text("Has realizado cambios en la rutina. ¿Deseas actualizarla con estos cambios?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _finalizeRoutine(appState, updateRoutine: false);
                },
                child: Text("No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _finalizeRoutine(appState, updateRoutine: true);
                },
                child: Text("Sí"),
              ),
            ],
          );
        },
      );
    } else {
      // No hay cambios, finalizar rutina
      _finalizeRoutine(appState, updateRoutine: false);
    }
  }

  bool _hasRoutineChanged() {
    if (originalExercises.length != exercises.length) return true;
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i].name != originalExercises[i].name) return true;
      if (exercises[i].series.length != originalExercises[i].series.length) return true;
    }
    return false;
  }

  void _finalizeRoutine(AppState appState, {required bool updateRoutine}) {
    if (updateRoutine && widget.routine != null) {
      // Actualizar la rutina en AppState y en la base de datos
      Routine updatedRoutine = widget.routine!.copyWith(
        exercises: exercises,
      );
      appState.updateRoutine(updatedRoutine);
    }

    // Guardar la rutina completada sin modificar la original
    Routine completedRoutine = widget.routine!.copyWith(
      exercises: exercises,
    );

    try {
      appState.completeRoutine(completedRoutine, _displayDuration.value);
    } catch (e) {
      print("Error al completar la rutina: $e");
      // Opcional: Mostrar un mensaje de error al usuario
    }
    appState.restoreRoutine();

    // Navegar de vuelta a la pantalla principal
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainNavigationScreen()),
      (route) => false,
    );
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
        id: widget.routine?.id ?? '',
        name: routineName,
        dateCreated: widget.routine?.dateCreated ?? DateTime.now(),
        exercises: exercises,
        duration: _displayDuration.value,
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
              id: Uuid().v4(), // Asignar un ID único
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

        // Inicializar controladores para la nueva serie
        for (var series in exercise.series) {
          weightControllers[series.id] = TextEditingController();
          repsControllers[series.id] = TextEditingController();
          exertionControllers[series.id] = TextEditingController();
        }
      });
    }
  }

  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      Series newSeries = Series(
        id: Uuid().v4(),
        previousWeight: null,
        previousReps: null,
        weight: 0,
        reps: 0,
        perceivedExertion: 0,
        lastSavedPerceivedExertion: null,
        isCompleted: false,
      );
      exercise.series.add(newSeries);

      // Inicializar controladores sin texto
      weightControllers[newSeries.id] = TextEditingController();
      repsControllers[newSeries.id] = TextEditingController();
      exertionControllers[newSeries.id] = TextEditingController();
    });
  }

  void _deleteSeries(Exercise exercise, int seriesIndex) {
    setState(() {
      Series seriesToRemove = exercise.series[seriesIndex];

      // Liberar y eliminar los controladores asociados
      weightControllers[seriesToRemove.id]?.dispose();
      weightControllers.remove(seriesToRemove.id);
      repsControllers[seriesToRemove.id]?.dispose();
      repsControllers.remove(seriesToRemove.id);
      exertionControllers[seriesToRemove.id]?.dispose();
      exertionControllers.remove(seriesToRemove.id);

      exercise.series.removeAt(seriesIndex);
    });
  }

  void _deleteExercise(Exercise exercise) {
    setState(() {
      // Liberar controladores asociados a las series del ejercicio
      for (var series in exercise.series) {
        weightControllers[series.id]?.dispose();
        weightControllers.remove(series.id);
        repsControllers[series.id]?.dispose();
        repsControllers.remove(series.id);
        exertionControllers[series.id]?.dispose();
        exertionControllers.remove(series.id);
      }
      exercises.remove(exercise);
    });
  }

  Future<void> _replaceExercise(Exercise oldExercise) async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExerciseSelectionScreen()),
    );

    if (selectedExercise != null) {
      setState(() {
        // Eliminar controladores del ejercicio antiguo
        for (var series in oldExercise.series) {
          weightControllers[series.id]?.dispose();
          weightControllers.remove(series.id);
          repsControllers[series.id]?.dispose();
          repsControllers.remove(series.id);
          exertionControllers[series.id]?.dispose();
          exertionControllers.remove(series.id);
        }
        int index = exercises.indexOf(oldExercise);

        // Crear nuevo ejercicio
        final newExercise = Exercise(
          id: selectedExercise['id'].toString(),
          name: selectedExercise['name'],
          series: [
            Series(
              id: Uuid().v4(),
              previousWeight: null,
              previousReps: null,
              weight: 0,
              reps: 0,
              perceivedExertion: 0,
              isCompleted: false,
            ),
          ],
        );

        // Reemplazar en la lista
        exercises[index] = newExercise;

        // Inicializar controladores para el nuevo ejercicio
        for (var series in newExercise.series) {
          weightControllers[series.id] = TextEditingController();
          repsControllers[series.id] = TextEditingController();
          exertionControllers[series.id] = TextEditingController();
        }
      });
    }
  }

  void _autofillSeries(Series series) {
    setState(() {
      if (series.weight == 0 && series.previousWeight != null) {
        series.weight = series.previousWeight!;
        weightControllers[series.id]?.text = series.weight.toString();
      }
      if (series.reps == 0 && series.previousReps != null) {
        series.reps = series.previousReps!;
        repsControllers[series.id]?.text = series.reps.toString();
      }
      if (series.perceivedExertion == 0 && series.lastSavedPerceivedExertion != null) {
        series.perceivedExertion = series.lastSavedPerceivedExertion!;
        exertionControllers[series.id]?.text = series.perceivedExertion.toString();
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
            ValueListenableBuilder<Duration>(
              valueListenable: _displayDuration,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Tiempo Transcurrido: ${_formatDuration(value)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              },
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
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteExercise(exercise);
                              } else if (value == 'replace') {
                                _replaceExercise(exercise);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar Ejercicio'),
                                ),
                                PopupMenuItem(
                                  value: 'replace',
                                  child: Text('Reemplazar Ejercicio'),
                                ),
                              ];
                            },
                          ),
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
                          children: exercise.series.asMap().entries.map((entry) {
                            int seriesIndex = entry.key;
                            Series series = entry.value;

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
                                        controller: weightControllers[series.id],
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
                                        controller: repsControllers[series.id],
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
                                        controller: exertionControllers[series.id],
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
