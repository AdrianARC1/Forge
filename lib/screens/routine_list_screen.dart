import 'package:flutter/material.dart';
import 'package:forge/screens/create_routine_screen.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'routine_detail_screen.dart';
import 'routine_execution_screen.dart';

class RoutineListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Rutinas")),
      body: ListView.builder(
        itemCount: appState.routines.length,
        itemBuilder: (context, index) {
          final routine = appState.routines[index];
          return ListTile(
            title: Text(routine.name),
            subtitle: Text('Creada el: ${routine.dateCreated}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutineExecutionScreen(routine: routine),
                      ),
                    );
                  },
                  tooltip: 'Iniciar Rutina',
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    appState.deleteRoutine(routine.id);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutineDetailScreen(routine: routine),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateRoutineScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
