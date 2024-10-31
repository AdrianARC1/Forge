import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

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
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(completedRoutine['name']),
                    subtitle: Text(
                      'Completada el: ${completedRoutine['dateCompleted']}\n'
                      'Duración: ${Duration(seconds: completedRoutine['duration'])}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
