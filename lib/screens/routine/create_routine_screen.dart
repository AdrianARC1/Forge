import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exercice_selection_screen.dart';
import '../../app_state.dart';

class CreateRoutineScreen extends StatefulWidget {
  @override
  _CreateRoutineScreenState createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  final FocusNode _routineNameFocusNode = FocusNode();
  List<Exercise> selectedExercises = [];

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
      // Quitar el enfoque del campo de nombre y ponerlo en el primer campo de la serie
      FocusScope.of(context).unfocus();
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
    FocusScope.of(context).unfocus(); // Quita el enfoque del campo de nombre
  }

  void _deleteSeries(Exercise exercise, int seriesIndex) {
    setState(() {
      exercise.series.removeAt(seriesIndex);
    });
  }

  void _cancelCreation() {
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

    final newRoutine = Routine(
      id: DateTime.now().toString(),
      name: routineName,
      dateCreated: DateTime.now(),
      exercises: selectedExercises,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.saveRoutine(newRoutine);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Rutina"),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: _cancelCreation,
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
                  focusNode: _routineNameFocusNode,
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
                                      FocusScope.of(context).unfocus(); // Quita el enfoque del campo de nombre
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
}
