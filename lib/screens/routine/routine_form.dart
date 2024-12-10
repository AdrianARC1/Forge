// lib/screens/routine/routine_form.dart

import 'package:flutter/material.dart';
import 'package:forge/styles/global_styles.dart';
import 'package:provider/provider.dart';
import '../exercice_selection_screen.dart';
import '../../app_state.dart';
import 'package:uuid/uuid.dart';
import '../widgets/exercise_form_widget.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/app_bar_button.dart';
import 'package:toastification/toastification.dart';

class RoutineForm extends StatefulWidget {
  final Routine? routine; // Si es null, estamos creando una nueva rutina
  final String title;
  final Function(Routine) onSave;
  final Function() onCancel;

  const RoutineForm({
    super.key,
    this.routine,
    required this.title,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> {
  final TextEditingController _routineNameController = TextEditingController();
  final FocusNode _routineNameFocusNode = FocusNode();
  List<Exercise> selectedExercises = [];

  Map<String, TextEditingController> weightControllers = {};
  Map<String, TextEditingController> repsControllers = {};
  Map<String, TextEditingController> exertionControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      // Estamos editando una rutina existente
      _routineNameController.text = widget.routine!.name;
      selectedExercises = widget.routine!.exercises;

      // Inicializar controladores para los ejercicios existentes
      for (var exercise in selectedExercises) {
        for (var series in exercise.series) {
          weightControllers[series.id] =
              TextEditingController(text: series.weight.toString());
          repsControllers[series.id] =
              TextEditingController(text: series.reps.toString());
          exertionControllers[series.id] = TextEditingController(); 
        }
      }
    }
  }

  Future<void> _addExercise() async {
    final selectedExercisesFromScreen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
    );

    if (selectedExercisesFromScreen != null && selectedExercisesFromScreen is List) {
      setState(() {
        for (var selectedExercise in selectedExercisesFromScreen) {
          final exercise = Exercise(
            id: selectedExercise['id'].toString(),
            name: selectedExercise['name'],
            gifUrl: selectedExercise['gifUrl'],
            series: [
              Series(
                id: const Uuid().v4(),
                weight: 0,
                reps: 0,
                perceivedExertion: 0,
                isCompleted: false,
              ),
            ],
          );
          selectedExercises.add(exercise);

          // Inicializar controladores para la nueva serie
          for (var series in exercise.series) {
            weightControllers[series.id] = TextEditingController();
            repsControllers[series.id] = TextEditingController();
            exertionControllers[series.id] = TextEditingController();
          }
        }
      });
    }
  }

  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      Series newSeries = Series(
        id: const Uuid().v4(),
        weight: 0,
        reps: 0,
        perceivedExertion: 0,
        isCompleted: false,
      );
      exercise.series.add(newSeries);

      // Inicializar controladores
      weightControllers[newSeries.id] = TextEditingController();
      repsControllers[newSeries.id] = TextEditingController();
      exertionControllers[newSeries.id] = TextEditingController();
    });
  }

  void _deleteSeries(Exercise exercise, int seriesIndex) {
    setState(() {
      Series seriesToRemove = exercise.series[seriesIndex];

      // Liberar y eliminar controladores
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
      // Liberar controladores de todas las series del ejercicio
      for (var series in exercise.series) {
        weightControllers[series.id]?.dispose();
        weightControllers.remove(series.id);
        repsControllers[series.id]?.dispose();
        repsControllers.remove(series.id);
        exertionControllers[series.id]?.dispose();
        exertionControllers.remove(series.id);
      }

      selectedExercises.remove(exercise);
    });
  }

  void _cancel() {
    widget.onCancel();
  }

  bool _areAllSeriesCompleted() {
    for (var exercise in selectedExercises) {
      for (var series in exercise.series) {
        int weight = int.tryParse(weightControllers[series.id]?.text ?? '') ?? 0;
        int reps = int.tryParse(repsControllers[series.id]?.text ?? '') ?? 0;
        if (weight == 0 || reps == 0) return false;
      }
    }
    return true;
  }

  void _saveRoutine() async {
    FocusScope.of(context).unfocus();

    if (!_areAllSeriesCompleted()) {
      toastification.show(
        context: context,
        title: const Text('Atención'),
        description: const Text("Completa todas las series antes de guardar"),
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.bottomCenter
      );
      return;
    }

    final routineName = _routineNameController.text.trim();
    if (routineName.isEmpty) {
      toastification.show(
        context: context,
        title: const Text('Atención'),
        description: const Text("Por favor, ingresa un nombre para la rutina"),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.bottomCenter
      );
      return;
    }

    if (selectedExercises.isEmpty) {
      toastification.show(
        context: context,
        title: const Text('Atención'),
        description: const Text("Agrega al menos un ejercicio a la rutina"),
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.bottomCenter

      );
      return;
    }

    // Actualizar los valores de weight y reps en las series
    for (var exercise in selectedExercises) {
      for (var series in exercise.series) {
        series.weight =
            int.tryParse(weightControllers[series.id]?.text ?? '') ?? 0;
        series.reps = int.tryParse(repsControllers[series.id]?.text ?? '') ?? 0;
      }
    }

    final newRoutine = Routine(
      id: widget.routine?.id ?? const Uuid().v4(),
      name: routineName,
      dateCreated: widget.routine?.dateCreated ?? DateTime.now(),
      exercises: selectedExercises,
    );

    widget.onSave(newRoutine);
      toastification.show(
        context: context,
        title: const Text('Rutina guardada'),
        description: const Text("La rutina se ha guardado correctamente"),
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 2),
      );
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    _routineNameFocusNode.dispose();
    for (var controller in weightControllers.values) {
      controller.dispose();
    }
    for (var controller in repsControllers.values) {
      controller.dispose();
    }
    for (var controller in exertionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _replaceExercise(Exercise oldExercise) async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
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
        int index = selectedExercises.indexOf(oldExercise);

        // Crear nuevo ejercicio
        final newExercise = Exercise(
          id: selectedExercise['id'].toString(),
          name: selectedExercise['name'],
          gifUrl: selectedExercise['gifUrl'],
          series: [
            Series(
              id: const Uuid().v4(),
              weight: 0,
              reps: 0,
              perceivedExertion: 0,
              isCompleted: false,
            ),
          ],
        );

        // Reemplazar en la lista
        selectedExercises[index] = newExercise;

        // Inicializar controladores para el nuevo ejercicio
        for (var series in newExercise.series) {
          weightControllers[series.id] = TextEditingController();
          repsControllers[series.id] = TextEditingController();
          exertionControllers[series.id] = TextEditingController();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return BaseScaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        leadingWidth: 100,
        title: Text(
          widget.title,
          style: GlobalStyles.insideAppTitleStyle,
        ),
        centerTitle: true,
        leading: AppBarButton(
          text: 'Cancelar',
          onPressed: _cancel,
          textColor: GlobalStyles.textColor,
          backgroundColor: Colors.transparent,
        ),
        actions: [
          AppBarButton(
            text: 'Guardar',
            onPressed: _saveRoutine,
            textColor: GlobalStyles.buttonTextStyle.color,
            backgroundColor: GlobalStyles.backgroundButtonsColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo para el nombre de la rutina con sombra en el borde inferior
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _routineNameController,
                      focusNode: _routineNameFocusNode,
                      decoration: InputDecoration(
                        hintText: "Nombre de la rutina",
                        hintStyle: GlobalStyles.subtitleStyle.copyWith(
                          color: GlobalStyles.placeholderColor,
                        ),
                        filled: false, 
                        border: InputBorder.none,
                      ),
                      style: GlobalStyles.subtitleStyle,
                    ),
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
                  ],
                ),
                const SizedBox(height: 20), 

                if (selectedExercises.isEmpty) ...[
                  const SizedBox(height: 80),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Introduce algún ejercicio para empezar',
                      style: GlobalStyles.subtitleStyleHighFont,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: SizedBox(
                      width: double.infinity, 
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.backgroundButtonsColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          "Introducir ejercicio",
                          style: GlobalStyles.buttonTextStyle,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Lista de ejercicios
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      children: selectedExercises.map((exercise) {
                        final maxRecord = appState.maxExerciseRecords[exercise.name];

                        return ExerciseFormWidget(
                          exercise: exercise,
                          onAddSeries: () => _addSeriesToExercise(exercise),
                          onDeleteSeries: (seriesIndex) => _deleteSeries(exercise, seriesIndex),
                          weightControllers: weightControllers,
                          repsControllers: repsControllers,
                          exertionControllers: exertionControllers,
                          isExecution: false,
                          onDeleteExercise: () => _deleteExercise(exercise),
                          onReplaceExercise: () => _replaceExercise(exercise),
                          maxRecord: maxRecord,
                          allowEditing: true,
                          showMaxRecord: widget.routine != null,
                        );
                      }).toList(),
                    ),
                  ),
                  // Botón para añadir más ejercicios
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlobalStyles.backgroundButtonsColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          "Introducir ejercicio",
                          style: GlobalStyles.buttonTextStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
