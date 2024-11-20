// lib/screens/routine/routine_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../widgets/exercise_form_widget.dart';
import 'edit_routine_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Routine routine;
  final bool isFromHistory;
  final Duration? duration;
  final int? totalVolume;
  final DateTime? completionDate;

  RoutineDetailScreen({
    required this.routine,
    this.isFromHistory = false,
    this.duration,
    this.totalVolume,
    this.completionDate,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: isFromHistory
            ? null
            : [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRoutineScreen(routine: routine),
                      ),
                    );
                  },
                  tooltip: 'Editar Rutina',
                ),
              ],
      ),
      body: Column(
        children: [
          if (isFromHistory)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Finalizada el: ${completionDate != null ? "${completionDate!.toLocal().toString().split(' ')[0]}" : 'N/A'}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Duración: ${duration != null ? "${duration!.inHours}h ${duration!.inMinutes.remainder(60)}min" : 'N/A'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Volumen Total: ${totalVolume != null ? "$totalVolume kg" : 'N/A'}",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: routine.exercises.map((exercise) {
                  final maxRecord = appState.maxExerciseRecords[exercise.name];

                  return ExerciseFormWidget(
                    exercise: exercise,
                    weightControllers: {}, // Controladores vacíos
                    repsControllers: {},
                    exertionControllers: {},
                    isExecution: false,
                    isReadOnly: true,
                    maxRecord: maxRecord,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
