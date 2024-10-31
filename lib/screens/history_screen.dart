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

                // Crear objeto Routine para pasar a RoutineDetailScreen
                final routine = Routine(
                  id: completedRoutine['routineId'] ?? '',
                  name: name,
                  dateCreated: DateTime.tryParse(dateCompleted) ?? DateTime.now(),
                  exercises: (completedRoutine['exercises'] as List<dynamic>?)
                          ?.map((exerciseData) => Exercise(
                                id: exerciseData['id'] ?? '',
                                name: exerciseData['name'] ?? 'Ejercicio',
                                series: [], // Aquí puedes ajustar si tienes una lista de series
                              ))
                          .toList() ??
                      [],
                  duration: duration,
                );

                // Previsualización de los primeros 3 ejercicios
                final previewExercises = (completedRoutine['exercises'] as List<dynamic>?)
                        ?.take(3)
                        .map((exercise) => exercise as Map<String, dynamic>)
                        .toList() ??
                    [];

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
                        ...previewExercises.map((exercise) => Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${exercise['seriesCount'] ?? 0} series ${exercise['name'] ?? 'Ejercicio'} (${exercise['equipment'] ?? 'Equipo'})",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )),
                        if (((completedRoutine['exercises'] as List<dynamic>?)?.length ?? 0) > 3)
                          Text(
                            "Ver ${(completedRoutine['exercises'] as List<dynamic>).length - 3} más ejercicios",
                            style: TextStyle(color: Colors.blue),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutineDetailScreen(
                            routine: routine,
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
