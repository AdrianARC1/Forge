import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:forge/app_state.dart';
import 'package:forge/screens/exercice_selection_screen.dart';

mixin ExerciseManagementMixin<T extends StatefulWidget> on State<T> {
  List<Exercise> exercises = [];
  Map<String, TextEditingController> weightControllers = {};
  Map<String, TextEditingController> repsControllers = {};
  Map<String, TextEditingController> exertionControllers = {};

  Future<void> addExercise() async {
    final selectedExercisesFromScreen = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen()),
    );

    if (selectedExercisesFromScreen != null && selectedExercisesFromScreen is List) {
      setState(() {
        for (var selectedExercise in selectedExercisesFromScreen) {
          final exercise = Exercise(
            id: const Uuid().v4(),
            name: selectedExercise['name'],
            gifUrl: selectedExercise['gifUrl'],
            series: [
              Series(
                id: const Uuid().v4(),
                weight: 0,
                reps: 0,
                perceivedExertion: 1,
                isCompleted: false,
              ),
            ],
          );
          exercises.add(exercise);

          for (var series in exercise.series) {
            weightControllers[series.id] = TextEditingController();
            repsControllers[series.id] = TextEditingController();
            exertionControllers[series.id] = TextEditingController();
          }
        }
      });
    }
  }

  void addSeriesToExercise(Exercise exercise) {
    setState(() {
      Series newSeries = Series(
        id: const Uuid().v4(),
        weight: 0,
        reps: 0,
        perceivedExertion: 1,
        isCompleted: false,
      );
      exercise.series.add(newSeries);

      weightControllers[newSeries.id] = TextEditingController();
      repsControllers[newSeries.id] = TextEditingController();
      exertionControllers[newSeries.id] = TextEditingController();
    });
  }

  void deleteSeries(Exercise exercise, int seriesIndex) {
    setState(() {
      Series seriesToRemove = exercise.series[seriesIndex];

      weightControllers[seriesToRemove.id]?.dispose();
      weightControllers.remove(seriesToRemove.id);
      repsControllers[seriesToRemove.id]?.dispose();
      repsControllers.remove(seriesToRemove.id);
      exertionControllers[seriesToRemove.id]?.dispose();
      exertionControllers.remove(seriesToRemove.id);

      exercise.series.removeAt(seriesIndex);
    });
  }

  void deleteExercise(Exercise exercise) {
    setState(() {
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

  Future<void> replaceExercise(Exercise oldExercise) async {
    final selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSelectionScreen(singleSelection: true)),
    );

    if (selectedExercise != null) {
      setState(() {
        for (var series in oldExercise.series) {
          weightControllers[series.id]?.dispose();
          weightControllers.remove(series.id);
          repsControllers[series.id]?.dispose();
          repsControllers.remove(series.id);
          exertionControllers[series.id]?.dispose();
          exertionControllers.remove(series.id);
        }
        int index = exercises.indexOf(oldExercise);

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

        exercises[index] = newExercise;

        for (var series in newExercise.series) {
          weightControllers[series.id] = TextEditingController();
          repsControllers[series.id] = TextEditingController();
          exertionControllers[series.id] = TextEditingController();
        }
      });
    }
  }

  void autofillSeries(Series series, {bool markCompleted = true}) {
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
      if (markCompleted) {
        series.isCompleted = true;
      }
    });
  }
}
