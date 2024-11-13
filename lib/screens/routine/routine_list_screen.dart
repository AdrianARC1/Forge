import 'package:flutter/material.dart';
import 'package:forge/screens/routine/create_routine_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'edit_routine_screen.dart';
import 'routine_detail_screen.dart';
import 'routine_execution_screen.dart';

class RoutineListScreen extends StatefulWidget {
  @override
  _RoutineListScreenState createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Entrenamiento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutineExecutionScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.play_arrow),
                label: Text("Empezar Entrenamiento Vacío"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                  backgroundColor: Colors.grey[400],
                ),
              ),
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    "Rutinas",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
              ],
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                  Text(
                    "Mis rutinas (${appState.routines.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Envuelve el AnimatedSwitcher en un Expanded y ClipRect para limitar el movimiento
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300), // Duración total para expansión
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    if (child.key == ValueKey(true)) {
                      // Widget entrando: desliza desde arriba con 400ms
                      final inAnimation = Tween<Offset>(
                        begin: Offset(0, -0.2),
                        end: Offset(0, 0),
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ));
                      return SlideTransition(
                        position: inAnimation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    } else {
                      // Widget saliendo: desliza hacia abajo con 100ms (25% de 400ms)
                      final outAnimation = Tween<Offset>(
                        begin: Offset(0, 0),
                        end: Offset(0, 0.2),
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Interval(
                            0.0,
                            0.25, // 25% del tiempo total (100ms)
                            curve: Curves.easeInOut,
                          ),
                        ),
                      );
                      final fadeOut = Tween<double>(
                        begin: 1.0,
                        end: 0.0,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Interval(
                            0.0,
                            0.25, // 25% del tiempo total (100ms)
                            curve: Curves.easeInOut,
                          ),
                        ),
                      );
                      return SlideTransition(
                        position: outAnimation,
                        child: FadeTransition(
                          opacity: fadeOut,
                          child: child,
                        ),
                      );
                    }
                  },
                  layoutBuilder:
                      (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _isExpanded
                      ? ListView.builder(
                          key: ValueKey(true),
                          itemCount: appState.routines.length,
                          itemBuilder: (context, index) {
                            final routine = appState.routines[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RoutineDetailScreen(routine: routine),
                                  ),
                                );
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            routine.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditRoutineScreen(
                                                            routine: routine),
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                appState.deleteRoutine(
                                                    routine.id);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                              return [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Editar Rutina'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child:
                                                      Text('Eliminar Rutina'),
                                                ),
                                              ];
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        routine.exercises
                                            .map((exercise) =>
                                                exercise.name)
                                            .join(", "),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RoutineExecutionScreen(
                                                        routine: routine),
                                              ),
                                            );
                                          },
                                          child: Text("Empezar Rutina"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 15),
                                            textStyle:
                                                TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : SizedBox.shrink(
                          key: ValueKey(false),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
