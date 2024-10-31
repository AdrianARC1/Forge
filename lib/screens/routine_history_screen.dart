import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'routine_detail_screen.dart';

class RoutineHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de Rutinas"),
      ),
      body: ListView.builder(
        itemCount: appState.routines.length,
        itemBuilder: (context, index) {
          final routine = appState.routines[index];
          final timeElapsed = DateTime.now().difference(routine.dateCreated);

          return ListTile(
            title: Text(routine.name),
            subtitle: Text(
              'Hace ${timeElapsed.inDays} días',
              style: TextStyle(color: Colors.grey),
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
    );
  }
}
