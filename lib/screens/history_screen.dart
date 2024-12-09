// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'routine/routine_detail_screen.dart';
import '../styles/global_styles.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Obtener las últimas 10 rutinas completadas
    final completedRoutines = appState.completedRoutines.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial", style: GlobalStyles.insideAppTitleStyle),
        centerTitle: true,
      ),
      backgroundColor: GlobalStyles.backgroundColor,
      body: completedRoutines.isEmpty
          ? const Center(
              child: Text(
                "No hay rutinas completadas en el historial.",
                style: GlobalStyles.subtitleStyle,
              ),
            )
          : ListView.builder(
              itemCount: completedRoutines.length,
              itemBuilder: (context, index) {
                final completedRoutine = completedRoutines[index];

                final String name = completedRoutine.name;
                final DateTime dateCompleted = completedRoutine.dateCompleted ?? DateTime.now();
                final Duration duration = completedRoutine.duration;
                final int totalVolume = completedRoutine.totalVolume;

                // Obtener la lista de ejercicios y la vista previa de los primeros 3 ejercicios
                final exercises = completedRoutine.exercises;
                final previewExercises = exercises.take(3).toList();

                // Calcular los ejercicios restantes para el texto "ver más"
                final int remainingExercises = exercises.length > 3 ? exercises.length - 3 : 0;

                // Calcular cuántos días han pasado desde que se completó la rutina
                final daysAgo = DateTime.now().difference(dateCompleted).inDays;

                // Formatear la duración
                final durationStr = _formatDuration(duration);

                return Card(
                  color: GlobalStyles.inputBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        // Foto de perfil del usuario
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage('assets/icon/icon.png'), // Reemplaza con la imagen de perfil del usuario
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre de la rutina
                              Text(
                                name,
                                style: GlobalStyles.subtitleStyle.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Hace cuántos días
                              Text(
                                daysAgo == 0
                                    ? 'Hoy'
                                    : daysAgo == 1
                                        ? 'Hace 1 día'
                                        : 'Hace $daysAgo días',
                                style: GlobalStyles.subtitleStyle.copyWith(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Duración
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duración',
                                    style: GlobalStyles.subtitleStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    durationStr,
                                    style: GlobalStyles.subtitleStyle,
                                  ),
                                ],
                              ),
                            ),
                            // Volumen total
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Volumen',
                                    style: GlobalStyles.subtitleStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$totalVolume kg',
                                    style: GlobalStyles.subtitleStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Entrenamiento",
                          style: GlobalStyles.subtitleStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Mostrar los primeros 3 ejercicios en la vista previa con imágenes
                        ...previewExercises.map((exercise) {
                          final seriesCount = exercise.series.length;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                // Imagen del ejercicio
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: exercise.gifUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            exercise.gifUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.image_not_supported);
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.image_not_supported),
                                ),
                                const SizedBox(width: 8),
                                // Nombre del ejercicio y series
                                Expanded(
                                  child: Text(
                                    "$seriesCount series ${exercise.name}",
                                    style: GlobalStyles.subtitleStyle,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Mostrar el texto "Ver x ejercicio(s) más" si hay más de 3 ejercicios
                        if (remainingExercises > 0)
                          GestureDetector(
                            onTap: () {
                              // Navegar al detalle de la rutina
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoutineDetailScreen(
                                    routine: completedRoutine,
                                    isFromHistory: true,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Ver $remainingExercises ejercicio(s) más",
                                style: GlobalStyles.subtitleStyle.copyWith(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Navegar al detalle de la rutina
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoutineDetailScreen(
                            routine: completedRoutine,
                            isFromHistory: true,
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

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      // Si hay horas, mostrar horas y minutos
      String hoursStr = '${hours}h';
      String minutesStr = minutes > 0 ? ' ${minutes}min' : '';
      return '$hoursStr$minutesStr';
    } else {
      // Si no hay horas, mostrar minutos y segundos
      String minutesStr = minutes > 0 ? '${minutes}min' : '';
      String secondsStr = seconds > 0 ? ' ${seconds}s' : '';
      return '$minutesStr$secondsStr'.trim();
    }
  }
}
