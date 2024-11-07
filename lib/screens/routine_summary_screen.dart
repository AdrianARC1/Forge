import 'package:flutter/material.dart';
import '../app_state.dart';

class RoutineSummaryScreen extends StatelessWidget {
  final Routine routine;
  final Duration duration;
  final VoidCallback onDiscard;
  final VoidCallback onResume;
  final VoidCallback onSave;

  RoutineSummaryScreen({
    required this.routine,
    required this.duration,
    required this.onDiscard,
    required this.onResume,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    int totalVolume = _calculateTotalVolume(routine);

    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen de Rutina'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Has completado la rutina "${routine.name}" en ${_formatDuration(duration)}.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Volumen Total Levantado: $totalVolume kg',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: routine.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = routine.exercises[index];
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('Series: ${exercise.series.length}'),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: onResume,
              child: Text('Volver a la Rutina'),
            ),
            ElevatedButton(
              onPressed: onDiscard,
              child: Text('Descartar Entrenamiento'),
            ),
            ElevatedButton(
              onPressed: onSave,
              child: Text('Guardar Rutina'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  int _calculateTotalVolume(Routine routine) {
    int totalVolume = 0;
    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalVolume += series.weight * series.reps;
      }
    }
    return totalVolume;
  }
}
