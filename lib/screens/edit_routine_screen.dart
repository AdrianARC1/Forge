import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exercice_selection_screen.dart';
import '../app_state.dart';

class EditRoutineScreen extends StatefulWidget {
  final Routine routine;

  EditRoutineScreen({required this.routine});

  @override
  _EditRoutineScreenState createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  List<Exercise> selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _routineNameController.text = widget.routine.name;
    selectedExercises = widget.routine.exercises;
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
        selectedExercises.add(exercise);
      });
    }
  }

  void _addSeriesToExercise(Exercise exercise) {
    setState(() {
      exercise.series.add(
        Series(
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

  void _cancelEdit() {
    Navigator.pop(context);
  }

  bool _areAllSeriesCompleted() {
    for (var exercise in selectedExercises) {
      for (var series in exercise.series) {
        if (!series.isCompleted) return false;
      }
    }
    return true;
  }

  void _saveEditedRoutine() async {
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

    final editedRoutine = widget.routine.copyWith(
      name: routineName,
      exercises: selectedExercises,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.updateRoutine(editedRoutine);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Rutina"),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: _cancelEdit,
            tooltip: 'Cancelar',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _routineNameController,
                  decoration: InputDecoration(
                    labelText: "Nombre de la Rutina",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Column(
                children: selectedExercises.map((exercise) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${seriesIndex + 1}"),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'KG',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      controller: TextEditingController()
                                        ..text = series.weight > 0
                                            ? series.weight.toString()
                                            : '',
                                      onChanged: (value) => series.weight =
                                          int.tryParse(value) ?? series.weight,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Reps',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      controller: TextEditingController()
                                        ..text = series.reps > 0
                                            ? series.reps.toString()
                                            : '',
                                      onChanged: (value) => series.reps =
                                          int.tryParse(value) ?? series.reps,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "RIR",
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      controller: TextEditingController()
                                        ..text = series.perceivedExertion > 0
                                            ? series.perceivedExertion.toString()
                                            : '',
                                      onChanged: (value) => series.perceivedExertion =
                                          int.tryParse(value) ?? series.perceivedExertion,
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
                  onPressed: _saveEditedRoutine,
                  child: Text("Guardar Cambios"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
