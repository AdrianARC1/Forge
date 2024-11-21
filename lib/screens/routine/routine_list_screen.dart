import 'package:flutter/material.dart';
import 'package:forge/screens/routine/create_routine_screen.dart';
import 'package:forge/screens/widgets/base_scaffold.dart';
import 'package:forge/styles/global_styles.dart';
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

    return BaseScaffold(
      appBar: AppBar(
        title: Text("Entrenamiento"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoutineExecutionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15), // Padding interno del botón
                alignment: Alignment.centerLeft, // Alineación del contenido a la izquierda
                backgroundColor: GlobalStyles.inputBackgroundColor,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20), // Padding izquierdo
                    child: Icon(Icons.play_arrow),
                  ),
                  SizedBox(width: 10), // Espaciado entre ícono y texto
                  Text("Empezar entrenamiento vacío"),
                ],
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
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2, // Controla cuánto espacio ocupa el botón
                      child: ElevatedButton.icon(
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
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Padding interno (vertical y horizontal)
                          alignment: Alignment.centerLeft, // Alinea el contenido hacia la izquierda
                          backgroundColor: GlobalStyles.inputBackgroundColor,
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Spacer(flex: 2), // Añade espacio proporcional después del botón
                  ],
                ),
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
                  _isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  color: Colors.white,
                ),
                Text(
                  "Mis rutinas (${appState.routines.length})",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300), // Duración total para expansión
                transitionBuilder: (Widget child, Animation<double> animation) {
                  if (child.key == ValueKey(true)) {
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
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
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
                                  builder: (context) => RoutineDetailScreen(routine: routine),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Bordes redondeados
                              ),
                              color: GlobalStyles.inputBackgroundColor, // Color del fondo de la tarjeta
                              child: Padding(
                                padding: const EdgeInsets.all(16.0), // Padding interno de la tarjeta
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          routine.name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          offset: const Offset(0.0, 40.0),
                                          color: Colors.white,
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
                                    SizedBox(height: 5),
                                    Text(
                                      routine.exercises.map((exercise) => exercise.name).join(", "),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Spacer(), // Empuja el botón hacia la derecha
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RoutineExecutionScreen(routine: routine),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Tamaño más compacto
                                            backgroundColor: GlobalStyles.backgroundButtonsColor, // Color del botón
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0), // Bordes del botón
                                            ),
                                            textStyle: TextStyle(
                                              fontSize: 15, // Tamaño de texto más pequeño
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          child: Text("Empezar Rutina"),
                                        ),
                                      ],
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
    );
  }
}
