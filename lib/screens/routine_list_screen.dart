import 'package:flutter/material.dart';
import 'package:forge/screens/create_routine_screen.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'routine_detail_screen.dart';

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutineDetailScreen(routine: routine),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                appState.deleteRoutine(routine.id);
              },
            ),
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
