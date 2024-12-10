import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../styles/global_styles.dart';
import '../routine/routine_detail_screen.dart';

class HistoryListWidget extends StatelessWidget {
  const HistoryListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final completedRoutines = appState.completedRoutines.take(10).toList();

    if (completedRoutines.isEmpty) {
      return const Center(
        child: Text(
          "No hay rutinas completadas en el historial.",
          style: GlobalStyles.subtitleStyle,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedRoutines.length,
      itemBuilder: (context, index) {
        final completedRoutine = completedRoutines[index];

        final String name = completedRoutine.name;
        final DateTime dateCompleted = completedRoutine.dateCompleted ?? DateTime.now();
        final Duration duration = completedRoutine.duration;
        final int totalVolume = completedRoutine.totalVolume;

        final exercises = completedRoutine.exercises;
        final previewExercises = exercises.take(3).toList();
        final remainingExercises = exercises.length > 3 ? exercises.length - 3 : 0;

        final daysAgo = DateTime.now().difference(dateCompleted).inDays;
        final durationStr = _formatDuration(duration);

        return Card(
          color: GlobalStyles.inputBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  backgroundImage: appState.profileImagePath != null
                      ? FileImage(File(appState.profileImagePath!))
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GlobalStyles.subtitleStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                ...previewExercises.map((exercise) {
                  final seriesCount = exercise.series.length;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
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
                if (remainingExercises > 0)
                  GestureDetector(
                    onTap: () {
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
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      String hoursStr = '${hours}h';
      String minutesStr = minutes > 0 ? ' ${minutes}min' : '';
      return '$hoursStr$minutesStr';
    } else {
      String minutesStr = minutes > 0 ? '${minutes}min' : '';
      String secondsStr = seconds > 0 ? ' ${seconds}s' : '';
      return '$minutesStr$secondsStr'.trim();
    }
  }
}
