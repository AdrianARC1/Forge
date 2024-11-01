import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'routine_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Historial de Rutinas Completadas")),
      body: appState.completedRoutines.isEmpty
          ? Center(child: Text("No hay rutinas completadas en el historial."))
          : ListView.builder(
              itemCount: appState.completedRoutines.length,
              itemBuilder: (context, index) {
                final completedRoutine = appState.completedRoutines[index];
                final String name = completedRoutine['name'] ?? 'Rutina';
                final String dateCompleted = completedRoutine['dateCompleted'] ?? '';
                final int durationInSeconds = completedRoutine['duration'] ?? 0;
                final int totalVolume = completedRoutine['totalVolume'] ?? 0;

                final Duration duration = Duration(seconds: durationInSeconds);

                final exercises = (completedRoutine['exercises'] as List<dynamic>)
                    .map((exerciseData) => Exercise(
                          id: exerciseData['id'] ?? '',
                          name: exerciseData['name'] ?? 'Ejercicio',
                          series: (exerciseData['series'] as List<dynamic>)
                              .map((seriesData) => Series(
                                    weight: seriesData['weight'] ?? 0,
                                    reps: seriesData['reps'] ?? 0,
                                    perceivedExertion: seriesData['perceivedExertion'] ?? 0,
                                    isCompleted: seriesData['isCompleted'] ?? false,
                                  ))
                              .toList(),
                        ))
                    .toList();

                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text("Volumen total: $totalVolume kg, Duración: ${duration.inMinutes} min"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutineDetailScreen(
                            routine: Routine(
                              id: completedRoutine['routineId'] ?? '',
                              name: name,
                              dateCreated: DateTime.tryParse(dateCompleted) ?? DateTime.now(),
                              exercises: exercises,
                              duration: duration,
                            ),
                            isFromHistory: true,
                            duration: duration,
                            totalVolume: totalVolume,
                            completionDate: DateTime.tryParse(dateCompleted) ?? DateTime.now(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
