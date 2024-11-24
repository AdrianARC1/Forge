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
import '../widgets/base_scaffold.dart'; // Importa BaseScaffold
import '../widgets/app_bar_button.dart'; // Importa AppBarButton
import '../../styles/global_styles.dart'; // Importa estilos globales

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
        print("Duración actual: ${_displayDuration.value.inSeconds} segundos");
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
          title: Text("Descartar Entrenamiento"),
          content: Text("¿Estás seguro de que deseas descartar este entrenamiento? Todos los progresos no guardados se perderán."),
          actions: [
            AppBarButton(
              text: "No",
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              textColor: Colors.blue,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: EdgeInsets.symmetric(horizontal: 8.0),
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

  void _saveRoutine() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (widget.routine == null) {
      // Es un entrenamiento vacío
      // Preguntar si desea guardar como nueva rutina
      String newRoutineName = "Nueva Rutina";
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Guardar Rutina"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("¿Deseas guardar esta rutina como una nueva rutina?"),
                TextField(
                  onChanged: (value) {
                    newRoutineName = value;
                  },
                  decoration: InputDecoration(
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
                  _finalizeRoutine(appState, saveAsNewRoutine: true, newRoutineName: newRoutineName);
                },
                textColor: Colors.blue,
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              AppBarButton(
                text: "No",
                onPressed: () {
                  Navigator.of(context).pop();
                  _finalizeRoutine(appState, saveAsNewRoutine: false);
                },
                textColor: Colors.blue,
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
            ],
          );
        },
      );
    } else {
      // Rutina existente: lógica actual
      bool routineChanged = _hasRoutineChanged();

      if (routineChanged) {
        String changeDescription = _getRoutineChanges();
        // Mostrar diálogo para actualizar la rutina
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Actualizar Rutina"),
              content: Text("$changeDescription\n¿Deseas actualizarla con estos cambios?"),
              actions: [
                AppBarButton(
                  text: "No",
                  onPressed: () {
                    Navigator.of(context).pop();
                    _finalizeRoutine(appState, updateRoutine: false);
                  },
                  textColor: Colors.blue,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                AppBarButton(
                  text: "Sí",
                  onPressed: () {
                    Navigator.of(context).pop();
                    _finalizeRoutine(appState, updateRoutine: true);
                  },
                  textColor: Colors.blue,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                AppBarButton(
                  text: "Cancelar",
                  onPressed: () {
                    Navigator.of(context).pop(); // Simplemente cierra el diálogo
                    // No se realiza ninguna acción adicional
                  },
                  textColor: Colors.red, // Opcional: Resaltar el botón de cancelar
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
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
  }

  bool _hasRoutineChanged() {
    if (originalExercises.length != exercises.length) return true;
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i].name != originalExercises[i].name) return true;
      if (exercises[i].series.length != originalExercises[i].series.length) return true;
    }
    return false;
  }

  void _finalizeRoutine(AppState appState, {bool updateRoutine = false, bool saveAsNewRoutine = false, String? newRoutineName}) async {
    try {
      if (saveAsNewRoutine && newRoutineName != null && newRoutineName.trim().isNotEmpty) {
        // Guardar la rutina como nueva rutina
        Routine newRoutine = Routine(
          id: Uuid().v4(),
          name: newRoutineName.trim(),
          dateCreated: DateTime.now(),
          exercises: exercises.map((exercise) {
            return Exercise(
              id: Uuid().v4(), // Genera un nuevo UUID para el ejercicio
              name: exercise.name,
              series: exercise.series.map((series) {
                return Series(
                  id: Uuid().v4(), // Genera un nuevo UUID para la serie
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
        );
        await appState.saveRoutine(newRoutine);
      }

      if (updateRoutine && widget.routine != null) {
        // Actualizar la rutina existente
        Routine updatedRoutine = widget.routine!.copyWith(
          exercises: exercises.map((exercise) {
            return Exercise(
              id: Uuid().v4(), // Genera un nuevo UUID para el ejercicio
              name: exercise.name,
              series: exercise.series.map((series) {
                return Series(
                  id: Uuid().v4(), // Genera un nuevo UUID para la serie
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
        );
        await appState.updateRoutine(updatedRoutine);
      }

      // Guardar la rutina completada en el historial con nuevos IDs
      Routine completedRoutine = Routine(
        id: Uuid().v4(),
        name: routineName,
        dateCreated: DateTime.now(),
        exercises: exercises.map((exercise) {
          return Exercise(
            id: Uuid().v4(), // Genera un nuevo UUID para el ejercicio
            name: exercise.name,
            series: exercise.series.map((series) {
              return Series(
                id: Uuid().v4(), // Genera un nuevo UUID para la serie
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
      );

      print("Duración antes de completar la rutina: ${_displayDuration.value.inSeconds} segundos");

      await appState.completeRoutine(completedRoutine, _displayDuration.value);
      appState.restoreRoutine();

      // Navegar de vuelta a la pantalla principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      print("Error en _finalizeRoutine: $e");
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
          title: Text("¿Cancelar rutina?"),
          content: Text("¿Realmente quieres cancelar la rutina en ejecución?"),
          actions: [
            AppBarButton(
              text: "No",
              onPressed: () => Navigator.of(context).pop(),
              textColor: Colors.blue,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: EdgeInsets.symmetric(horizontal: 8.0),
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

  String _getRoutineChanges() {
    int exercisesAdded = 0;
    int exercisesRemoved = 0;
    int seriesAdded = 0;
    int seriesRemoved = 0;

    // Mapear ejercicios originales y actuales por ID
    Map<String, Exercise> originalExercisesMap = {
      for (var exercise in originalExercises) exercise.id: exercise
    };
    Map<String, Exercise> currentExercisesMap = {
      for (var exercise in exercises) exercise.id: exercise
    };

    // Detectar ejercicios añadidos y eliminados
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

    // Comparar series dentro de los ejercicios existentes
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

    // Construir la descripción de cambios
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
          leadingWidth: 160, // Ajusta el ancho según tus necesidades
          title: Text(
            routineName,
            style: GlobalStyles.insideAppTitleStyle,
          ),
          centerTitle: true,
          leading: Container(
            padding: const EdgeInsets.only(left: 18.0), // Espaciado al inicio
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _minimizeRoutine();
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: GlobalStyles.textColor,
                    size: 24.0, // Ajusta el tamaño según tus necesidades
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
              padding: EdgeInsets.symmetric(horizontal: 18.0),
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0), // Añadido padding general
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
                          onAutofillSeries: autofillSeries,
                          maxRecord: maxRecord,
                          showMaxRecord: true,
                        );
                      }).toList(),
                      SizedBox(height: 2),
                      // Botón "Añadir Ejercicio" similar a "Introducir ejercicio" en routine_form.dart
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalStyles.backgroundButtonsColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: addExercise,
                          icon: Icon(Icons.add, color: Colors.black),
                          label: Text(
                            "Introducir Ejercicio",
                            style: GlobalStyles.buttonTextStyle,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
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
