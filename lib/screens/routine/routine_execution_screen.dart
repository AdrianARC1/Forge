// lib/screens/routine/routine_execution_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forge/screens/navigation/main_navigation_screen.dart';
import 'package:forge/screens/routine/routine_summary_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'package:uuid/uuid.dart';
import '../widgets/exercise_form_widget.dart';
import '../mixins/exercise_management_mixin.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final Routine? routine;

  RoutineExecutionScreen({this.routine});

  @override
  _RoutineExecutionScreenState createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> with ExerciseManagementMixin {
  List<Exercise> originalExercises = [];
  String routineName = "Entrenamiento Vacío";
  ValueNotifier<Duration> _displayDuration = ValueNotifier(Duration.zero);
  Timer? _localTimer;

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
              weight: 0,
              reps: 0,
              perceivedExertion: 0,
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
          // Restaurando rutina minimizada
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
          // Nueva rutina
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
    _displayDuration.dispose();
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
        if (!series.isCompleted || series.weight == 0 || series.reps == 0) return false;
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
                    return ExerciseFormWidget(
                      exercise: exercise,
                      onAddSeries: () => addSeriesToExercise(exercise),
                      onDeleteSeries: (seriesIndex) => deleteSeries(exercise, seriesIndex),
                      weightControllers: weightControllers,
                      repsControllers: repsControllers,
                      exertionControllers: exertionControllers,
                      isExecution: true,
                      onDeleteExercise: () => deleteExercise(exercise),
                      onReplaceExercise: () => replaceExercise(exercise),
                      onAutofillSeries: autofillSeries,
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
              onPressed: addExercise,
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
