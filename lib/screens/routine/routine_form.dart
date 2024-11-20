// lib/screens/routine/routine_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exercice_selection_screen.dart';
import '../../app_state.dart';
import 'package:uuid/uuid.dart';
import '../widgets/exercise_form_widget.dart';

class RoutineForm extends StatefulWidget {
  final Routine? routine; // Si es null, estamos creando una nueva rutina
  final String title;
  final Function(Routine) onSave;
  final Function() onCancel;

  RoutineForm({
    this.routine,
    required this.title,
    required this.onSave,
    required this.onCancel,
  });

  @override
  _RoutineFormState createState() => _RoutineFormState();
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
          weightControllers[series.id] = TextEditingController(text: series.weight.toString());
          repsControllers[series.id] = TextEditingController(text: series.reps.toString());
          exertionControllers[series.id] = TextEditingController(); // No se utiliza en creación/edición
        }
      }
    }
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
              id: Uuid().v4(),
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
      });
    }
  }

  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      Series newSeries = Series(
        id: Uuid().v4(),
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

    if (selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Agrega al menos un ejercicio a la rutina")),
      );
      return;
    }

    // Actualizar los valores de weight y reps en las series
    for (var exercise in selectedExercises) {
      for (var series in exercise.series) {
        series.weight = int.tryParse(weightControllers[series.id]?.text ?? '') ?? 0;
        series.reps = int.tryParse(repsControllers[series.id]?.text ?? '') ?? 0;
      }
    }

    final newRoutine = Routine(
      id: widget.routine?.id ?? Uuid().v4(),
      name: routineName,
      dateCreated: widget.routine?.dateCreated ?? DateTime.now(),
      exercises: selectedExercises,
    );

    widget.onSave(newRoutine);
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    _routineNameFocusNode.dispose();
    weightControllers.values.forEach((controller) => controller.dispose());
    repsControllers.values.forEach((controller) => controller.dispose());
    exertionControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: _cancel,
            tooltip: 'Cancelar',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Campo para el nombre de la rutina
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _routineNameController,
                  focusNode: _routineNameFocusNode,
                  decoration: InputDecoration(
                    labelText: "Nombre de la Rutina",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Lista de ejercicios
              Column(
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
                  );
                }).toList(),
              ),
              // Botones para añadir ejercicio y guardar rutina
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
      ),
    );
  }
  // Dentro de routine_form.dart, agrega el siguiente método dentro de la clase _RoutineFormState

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
      int index = selectedExercises.indexOf(oldExercise);

      // Crear nuevo ejercicio
      final newExercise = Exercise(
        id: selectedExercise['id'].toString(),
        name: selectedExercise['name'],
        series: [
          Series(
            id: Uuid().v4(),
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

}
