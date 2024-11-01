import 'package:flutter/material.dart';
import '../app_state.dart';
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Ejercicios",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: routine.exercises.length,
              itemBuilder: (context, index) {
                final exercise = routine.exercises[index];
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
                          Text("SERIE", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("KGxREPS", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("RIR", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Column(
                      children: exercise.series.map((series) {
                        int seriesIndex = exercise.series.indexOf(series);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${seriesIndex + 1}"), // Número de serie
                              Text("${series.weight} kg x ${series.reps}"), // Peso x Repeticiones
                              Text("${series.perceivedExertion}"), // RIR
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
