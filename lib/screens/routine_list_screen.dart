import 'package:flutter/material.dart';
import 'package:forge/screens/create_routine_screen.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'edit_routine_screen.dart';
import 'routine_detail_screen.dart';
import 'routine_execution_screen.dart';

class RoutineListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Entrenamiento")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutineExecutionScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text("Iniciar Entrenamiento Vacío"),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRoutineScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text("Nueva Rutina"),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: appState.routines.length,
                itemBuilder: (context, index) {
                  final routine = appState.routines[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      title: Text(routine.name),
                      subtitle: Text('Creada el: ${routine.dateCreated}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoutineExecutionScreen(routine: routine),
                                ),
                              );
                            },
                            child: Text("Empezar Rutina"),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditRoutineScreen(routine: routine),
                                  ),
                                );
                              } else if (value == 'delete') {
                                appState.deleteRoutine(routine.id);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar Rutina'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar Rutina'),
                                ),
                              ];
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
