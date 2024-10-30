import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

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
          final newRoutine = Routine(
            id: DateTime.now().toString(),
            name: "Nueva Rutina",
            dateCreated: DateTime.now(),
          );
          appState.addRoutine(newRoutine);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
