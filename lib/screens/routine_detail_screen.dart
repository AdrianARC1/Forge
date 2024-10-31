import 'package:flutter/material.dart';
import 'routine_execution_screen.dart';
import '../app_state.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Routine routine;

  RoutineDetailScreen({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Ejercicios y Series",
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
                          Text("SERIE"),
                          Text("KG"),
                          Text("REPS"),
                        ],
                      ),
                    ),
                    Column(
                      children: exercise.series.map((series) {
                        int seriesIndex = exercise.series.indexOf(series);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${seriesIndex + 1}"),
                              Text("${series.weight} kg"),
                              Text("${series.reps} reps"),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              label: Text("Iniciar Rutina"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoutineExecutionScreen(routine: routine),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
