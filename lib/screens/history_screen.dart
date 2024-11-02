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

                // Obtener la lista de ejercicios y la vista previa de los primeros 3 ejercicios
                final exercises = (completedRoutine['exercises'] as List<dynamic>?) ?? [];
                final previewExercises = exercises.take(3).toList();

                // Calcular los ejercicios restantes para el texto "ver más"
                final int remainingExercises = exercises.length > 3 ? exercises.length - 3 : 0;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completada el: $dateCompleted\n'
                          'Duración: ${duration.inHours}h ${duration.inMinutes.remainder(60)}min\n'
                          'Volumen total: $totalVolume kg',
                        ),
                        SizedBox(height: 8),
                        Text("Ejercicios:", style: TextStyle(fontWeight: FontWeight.bold)),
                        // Mostrar los primeros 3 ejercicios en la vista previa
                        ...previewExercises.map((exercise) {
                          final seriesCount = (exercise['series'] as List<dynamic>?)?.length ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "$seriesCount series ${exercise['name'] ?? 'Ejercicio'} (${exercise['equipment'] ?? 'Equipo'})",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        }),
                        // Mostrar el texto "Ver x ejercicio(s) más" si hay más de 3 ejercicios
                        if (remainingExercises > 0)
                          Text(
                            "Ver $remainingExercises ejercicio(s) más",
                            style: TextStyle(color: Colors.blue),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutineDetailScreen(
                            routine: Routine(
                              id: completedRoutine['routineId'] ?? '',
                              name: name,
                              dateCreated: DateTime.tryParse(dateCompleted) ?? DateTime.now(),
                              exercises: exercises.map((exerciseData) {
                                return Exercise(
                                  id: exerciseData['id'] ?? '',
                                  name: exerciseData['name'] ?? 'Ejercicio',
                                  series: (exerciseData['series'] as List<dynamic>).map((seriesData) {
                                    return Series(
                                      weight: seriesData['weight'] ?? 0,
                                      reps: seriesData['reps'] ?? 0,
                                      perceivedExertion: seriesData['perceivedExertion'] ?? 0,
                                      isCompleted: seriesData['isCompleted'] ?? false,
                                    );
                                  }).toList(),
                                );
                              }).toList(),
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
