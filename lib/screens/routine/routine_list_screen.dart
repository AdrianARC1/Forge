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
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text(
          "Entrenamiento",
          style: GlobalStyles.insideAppTitleStyle,
        ),
        centerTitle: true,
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
                    builder: (context) => const RoutineExecutionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10), // Padding interno del botón
                alignment: Alignment.centerLeft, // Alineación del contenido a la izquierda
                backgroundColor: GlobalStyles.inputBackgroundColor,
                foregroundColor: Colors.white,
              ),
              child: const Row(
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
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reemplazado el estilo en línea con GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold)
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text(
                  "Rutinas",
                  style: GlobalStyles.subtitleStyle, // Usando estilo global
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3, // Controla cuánto espacio ocupa el botón
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateRoutineScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Nueva Rutina"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Padding interno (vertical y horizontal)
                          alignment: Alignment.centerLeft,
                          backgroundColor: GlobalStyles.inputBackgroundColor,
                          foregroundColor: Colors.white,
                          textStyle: GlobalStyles.buttonTextStyle.copyWith(
                            fontSize: 14
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                  color: GlobalStyles.textColor,
                ),
                Text(
                  "Mis rutinas (${appState.routines.length})",
                  style: GlobalStyles.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300), // Duración total para expansión
                transitionBuilder: (Widget child, Animation<double> animation) {
                  if (child.key == const ValueKey(true)) {
                    final inAnimation = Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: const Offset(0, 0),
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
                      begin: const Offset(0, 0),
                      end: const Offset(0, 0.2),
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: const Interval(
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
                        curve: const Interval(
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
                        key: const ValueKey(true),
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
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // Bordes redondeados
                              ),
                              color: GlobalStyles.inputBackgroundColor, // Color del fondo de la tarjeta
                              child: Padding(
                                padding: const EdgeInsets.all(12.0), // Padding interno de la tarjeta
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Reemplazado el estilo en línea con GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 20)
                                        Text(
                                          routine.name,
                                          style: GlobalStyles.subtitleStyle.copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          offset: const Offset(0.0, 40.0),
                                          color: Colors.white,
                                          icon: const Icon(Icons.more_vert, color: Colors.white),
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
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Editar Rutina'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Eliminar Rutina'),
                                              ),
                                            ];
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    // Reemplazado el estilo en línea con GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold)
                                    Text(
                                      routine.exercises.map((exercise) => exercise.name).join(", "),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GlobalStyles.subtitleStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Spacer(), // Empuja el botón hacia la derecha
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
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Tamaño más compacto
                                            backgroundColor: GlobalStyles.backgroundButtonsColor, // Color del botón
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12), // Bordes del botón
                                            ),
                                            textStyle: GlobalStyles.buttonTextStyle.copyWith(
                                              fontSize: 15, // Tamaño de texto más pequeño
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          child: const Text("Empezar Rutina"),
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
                    : const SizedBox.shrink(
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
