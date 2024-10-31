import 'package:flutter/material.dart';
import '../app_state.dart';
import 'edit_routine_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Routine routine;

  RoutineDetailScreen({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
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
                          Text("SERIE"),
                          Text("KGxREPS"),
                          Text("RIR"),
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
                              Text("${series.weight} kg x ${series.reps}"),
                              Text("${series.perceivedExertion}"),
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
