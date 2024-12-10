// lib/screens/routine_execution_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forge/screens/navigation/main_navigation_screen.dart';
import 'package:forge/screens/routine/routine_summary_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'package:uuid/uuid.dart';
import '../widgets/exercise_form_widget.dart';
import '../mixins/exercise_management_mixin.dart';
import '../widgets/base_scaffold.dart'; 
import '../widgets/app_bar_button.dart';
import '../../styles/global_styles.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineExecutionScreen({super.key, this.routine});

  @override
  State<RoutineExecutionScreen> createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> with ExerciseManagementMixin {
  List<Exercise> originalExercises = [];
  String routineName = "Entrenamiento Vacío";
  final ValueNotifier<Duration> _displayDuration = ValueNotifier(Duration.zero);
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
          gifUrl: exercise.gifUrl,
          series: exercise.series.map((series) {
            return Series(
              id: series.id,
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
      _displayDuration.value = Duration.zero; 
    }

    // Copia profunda de los ejercicios originales
    originalExercises = exercises.map((exercise) {
      return Exercise(
        id: exercise.id,
        name: exercise.name,
        series: exercise.series.map((series) {
          return Series(
            id: series.id,
            previousWeight: series.previousWeight,
            previousReps: series.previousReps,
            lastSavedWeight: series.lastSavedWeight,
            lastSavedReps: series.lastSavedReps,
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
    for (var controller in weightControllers.values) {
      controller.dispose();
    }
    for (var controller in repsControllers.values) {
      controller.dispose();
    }
    for (var controller in exertionControllers.values) {
      controller.dispose();
    }
    _localTimer?.cancel();
    _displayDuration.dispose();
    super.dispose();
  }

  void _startLocalTimer() {
    if (_localTimer == null || !_localTimer!.isActive) {
      _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _displayDuration.value += const Duration(seconds: 1);
        final appState = Provider.of<AppState>(context, listen: false);
        appState.minimizedRoutineDuration = _displayDuration.value;
      });
    }
  }

  void _finishRoutine() {
    if (!_areAllSeriesCompleted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todas las series para finalizar la rutina")),
      );
      return;
    }

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Descartar Entrenamiento"),
          content: const Text("¿Estás seguro de que deseas descartar este entrenamiento? Todos los progresos no guardados se perderán."),
          actions: [
            AppBarButton(
              text: "No",
              onPressed: () {
                Navigator.of(context).pop();
              },
              textColor: Colors.blue,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            AppBarButton(
              text: "Sí",
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.cancelMinimizedRoutine();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              textColor: Colors.red,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ],
        );
      },
    );
  }

  void _resumeRoutine() {
    _startLocalTimer();
    Navigator.of(context).pop();
  }

  void _saveRoutine(Routine updatedRoutine) async {
    final appState = Provider.of<AppState>(context, listen: false);
    routineName = updatedRoutine.name; 

    if (widget.routine == null) {
      String newRoutineName = "Nueva Rutina";
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Guardar Rutina"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("¿Deseas guardar esta rutina como una nueva rutina?"),
                TextField(
                  onChanged: (value) {
                    newRoutineName = value;
                  },
                  decoration: const InputDecoration(
                    labelText: "Nombre de la nueva rutina",
                  ),
                ),
              ],
            ),
            actions: [
              AppBarButton(
                text: "Sí",
                onPressed: () {
                  Navigator.of(context).pop();
                  _finalizeRoutine(appState, saveAsNewRoutine: true, newRoutineName: newRoutineName, notes: updatedRoutine.notes);
                },
                textColor: Colors.blue,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
              AppBarButton(
                text: "No",
                onPressed: () {
                  Navigator.of(context).pop();
                  _finalizeRoutine(appState, saveAsNewRoutine: false, notes: updatedRoutine.notes);
                },
                textColor: Colors.blue,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
            ],
          );
        },
      );
    } else {
      bool routineChanged = _hasRoutineChanged();

      if (routineChanged) {
        String changeDescription = _getRoutineChanges();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Actualizar Rutina"),
              content: Text("$changeDescription\n¿Deseas actualizarla con estos cambios?"),
              actions: [
                AppBarButton(
                  text: "No",
                  onPressed: () {
                    Navigator.of(context).pop();
                    _finalizeRoutine(appState, updateRoutine: false, notes: updatedRoutine.notes);
                  },
                  textColor: Colors.blue,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                AppBarButton(
                  text: "Sí",
                  onPressed: () {
                    Navigator.of(context).pop();
                    _finalizeRoutine(appState, updateRoutine: true, notes: updatedRoutine.notes);
                  },
                  textColor: Colors.blue,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                AppBarButton(
                  text: "Cancelar",
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  textColor: Colors.red,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
              ],
            );
          },
        );
      } else {
        _finalizeRoutine(appState, updateRoutine: false, notes: updatedRoutine.notes);
      }
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

  void _finalizeRoutine(AppState appState, {bool updateRoutine = false, bool saveAsNewRoutine = false, String? newRoutineName, String? notes}) async {
    try {
      if (saveAsNewRoutine && newRoutineName != null && newRoutineName.trim().isNotEmpty) {
        Routine newRoutine = Routine(
          id: const Uuid().v4(),
          name: newRoutineName.trim(),
          dateCreated: DateTime.now(),
          exercises: exercises.map((exercise) {
            return Exercise(
              id: const Uuid().v4(),
              name: exercise.name,
              gifUrl: exercise.gifUrl,
              series: exercise.series.map((series) {
                return Series(
                  id: const Uuid().v4(),
                  previousWeight: series.previousWeight,
                  previousReps: series.previousReps,
                  lastSavedWeight: series.lastSavedWeight,
                  lastSavedReps: series.lastSavedReps,
                  weight: series.weight,
                  reps: series.reps,
                  perceivedExertion: series.perceivedExertion,
                  lastSavedPerceivedExertion: series.lastSavedPerceivedExertion,
                  isCompleted: series.isCompleted,
                );
              }).toList(),
            );
          }).toList(),
          duration: _displayDuration.value,
          notes: notes,
        );
        await appState.saveRoutine(newRoutine);
      }

      if (updateRoutine && widget.routine != null) {
        Routine updatedRoutine = widget.routine!.copyWith(
          exercises: exercises.map((exercise) {
            return Exercise(
              id: const Uuid().v4(),
              name: exercise.name,
              gifUrl: exercise.gifUrl,
              series: exercise.series.map((series) {
                return Series(
                  id: const Uuid().v4(),
                  previousWeight: series.previousWeight,
                  previousReps: series.previousReps,
                  lastSavedWeight: series.lastSavedWeight,
                  lastSavedReps: series.lastSavedReps,
                  weight: series.weight,
                  reps: series.reps,
                  perceivedExertion: series.perceivedExertion,
                  lastSavedPerceivedExertion: series.lastSavedPerceivedExertion,
                  isCompleted: series.isCompleted,
                );
              }).toList(),
            );
          }).toList(),
          duration: _displayDuration.value,
          notes: notes,
          name: routineName,
        );
        await appState.updateRoutine(updatedRoutine);
      }

      Routine completedRoutine = Routine(
        id: const Uuid().v4(),
        name: routineName,
        dateCreated: DateTime.now(),
        exercises: exercises.map((exercise) {
          return Exercise(
            id: const Uuid().v4(),
            name: exercise.name,
            gifUrl: exercise.gifUrl,
            series: exercise.series.map((series) {
              return Series(
                id: const Uuid().v4(),
                previousWeight: series.previousWeight,
                previousReps: series.previousReps,
                lastSavedWeight: series.lastSavedWeight,
                lastSavedReps: series.lastSavedReps,
                weight: series.weight,
                reps: series.reps,
                perceivedExertion: series.perceivedExertion,
                lastSavedPerceivedExertion: series.lastSavedPerceivedExertion,
                isCompleted: series.isCompleted,
              );
            }).toList(),
          );
        }).toList(),
        duration: _displayDuration.value,
        isCompleted: true,
        notes: notes,
      );

      await appState.completeRoutine(completedRoutine, _displayDuration.value);
      appState.restoreRoutine();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al finalizar la rutina: $e")),
      );
    }
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
          title: const Text("¿Cancelar rutina?"),
          content: const Text("¿Realmente quieres cancelar la rutina en ejecución?"),
          actions: [
            AppBarButton(
              text: "No",
              onPressed: () => Navigator.of(context).pop(),
              textColor: Colors.blue,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            AppBarButton(
              text: "Sí",
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.cancelMinimizedRoutine();
                _localTimer?.cancel();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              textColor: Colors.red,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    // Formato dinámico
    int totalSeconds = duration.inSeconds;
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = totalSeconds % 60;

    if (hours > 0) {
      return "${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}";
    } else if (minutes > 0) {
      return "${_twoDigits(minutes)}:${_twoDigits(seconds)}";
    } else {
      return "${_twoDigits(seconds)}s";
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _getRoutineChanges() {
    int exercisesAdded = 0;
    int exercisesRemoved = 0;
    int seriesAdded = 0;
    int seriesRemoved = 0;

    Map<String, Exercise> originalExercisesMap = {
      for (var exercise in originalExercises) exercise.id: exercise
    };
    Map<String, Exercise> currentExercisesMap = {
      for (var exercise in exercises) exercise.id: exercise
    };

    for (var exercise in exercises) {
      if (!originalExercisesMap.containsKey(exercise.id)) {
        exercisesAdded += 1;
        seriesAdded += exercise.series.length;
      }
    }

    for (var exercise in originalExercises) {
      if (!currentExercisesMap.containsKey(exercise.id)) {
        exercisesRemoved += 1;
        seriesRemoved += exercise.series.length;
      }
    }

    for (var exercise in exercises) {
      if (originalExercisesMap.containsKey(exercise.id)) {
        var originalExercise = originalExercisesMap[exercise.id]!;

        Map<String, Series> originalSeriesMap = {
          for (var series in originalExercise.series) series.id: series
        };
        Map<String, Series> currentSeriesMap = {
          for (var series in exercise.series) series.id: series
        };

        for (var series in exercise.series) {
          if (!originalSeriesMap.containsKey(series.id)) {
            seriesAdded += 1;
          }
        }

        for (var series in originalExercise.series) {
          if (!currentSeriesMap.containsKey(series.id)) {
            seriesRemoved += 1;
          }
        }
      }
    }

    List<String> changes = [];

    if (exercisesAdded > 0) {
      changes.add('Has añadido $exercisesAdded nuevo(s) ejercicio(s).');
    }
    if (exercisesRemoved > 0) {
      changes.add('Has eliminado $exercisesRemoved ejercicio(s).');
    }
    if (seriesAdded > 0) {
      changes.add('Has añadido $seriesAdded nueva(s) serie(s).');
    }
    if (seriesRemoved > 0) {
      changes.add('Has eliminado $seriesRemoved serie(s).');
    }
    if (changes.isEmpty) {
      return 'No hay cambios en la rutina.';
    } else {
      return changes.join('\n');
    }
  }

  int _calculateCompletedSeries() {
    int completed = 0;
    for (var exercise in exercises) {
      for (var s in exercise.series) {
        if (s.isCompleted) completed++;
      }
    }
    return completed;
  }

  double _calculateAverageRPE() {
    int totalRPE = 0;
    int count = 0;
    for (var exercise in exercises) {
      for (var s in exercise.series) {
        if (s.isCompleted && s.perceivedExertion > 0) {
          totalRPE += s.perceivedExertion;
          count++;
        }
      }
    }
    return count > 0 ? totalRPE / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    int completedSeries = _calculateCompletedSeries();
    double averageRPE = _calculateAverageRPE();

    return WillPopScope(
      onWillPop: () async {
        _minimizeRoutine();
        return false;
      },
      child: BaseScaffold(
        backgroundColor: GlobalStyles.backgroundColor,
        appBar: AppBar(
          backgroundColor: GlobalStyles.backgroundColor,
          elevation: 0,
          leadingWidth: 160,
          title: Text(
            routineName,
            style: GlobalStyles.insideAppTitleStyle,
          ),
          centerTitle: true,
          leading: Container(
            padding: const EdgeInsets.only(left: 18.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _minimizeRoutine();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: GlobalStyles.textColor,
                    size: 24.0,
                  ),
                ),
                AppBarButton(
                  text: 'Cancelar',
                  onPressed: _cancelExecution,
                  textColor: GlobalStyles.textColor,
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
          ),
          actions: [
            AppBarButton(
              text: 'Finalizar',
              onPressed: _finishRoutine,
              textColor: GlobalStyles.buttonTextStyle.color,
              backgroundColor: GlobalStyles.backgroundButtonsColor,
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats en fila alineados a la izquierda: Duración, Series, RPE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                // Alineación a la izquierda
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duración
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Duración", style: GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                        ValueListenableBuilder<Duration>(
                          valueListenable: _displayDuration,
                          builder: (context, value, child) {
                            return Text(
                              _formatDuration(value),
                              style: GlobalStyles.routineDataStyle,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Series Realizadas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Series", style: GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          "$completedSeries",
                          style: GlobalStyles.routineDataStyle,
                        ),
                      ],
                    ),
                  ),
                  // RPE Medio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("RPE Medio", style: GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          averageRPE.toStringAsFixed(1),
                          style: GlobalStyles.routineDataStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Línea divisoria
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: GlobalStyles.inputBorderColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    offset: const Offset(0, 5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                  child: Column(
                    children: [
                      ...exercises.map((exercise) {
                        final maxRecord = appState.maxExerciseRecords[exercise.name];

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
                          onAutofillSeries: (series, {bool markCompleted = true}) {
                            autofillSeries(series, markCompleted: markCompleted);
                            setState(() {}); 
                          },
                          maxRecord: maxRecord,
                          showMaxRecord: true,
                        );
                      }),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalStyles.backgroundButtonsColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            addExercise();
                            setState(() {});
                          },
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text(
                            "Introducir Ejercicio",
                            style: GlobalStyles.buttonTextStyle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
