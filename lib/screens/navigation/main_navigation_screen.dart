// main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:forge/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../routine/routine_list_screen.dart';
import '../history_screen.dart';
import '../routine/routine_execution_screen.dart';
import '../../styles/global_styles.dart'; // Importa el archivo de estilos

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    HistoryScreen(),
    RoutineListScreen(),
    ProfileScreen(), // Descomentar si tienes una pantalla de perfil
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: GlobalStyles.backgroundColor, // Usa el color de fondo global
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (appState.minimizedRoutine != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutineExecutionScreen(routine: appState.minimizedRoutine),
                    ),
                  );
                },
                child: Container(
                  color: Colors.blueAccent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "${appState.minimizedRoutine!.name}",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Text(
                              _formatDuration(appState.minimizedRoutineDuration),
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.play_arrow, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoutineExecutionScreen(routine: appState.minimizedRoutine),
                                  ),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () => _cancelMinimizedRoutine(context),
                              child: Icon(Icons.cancel, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    bottomNavigationBar: Container(
      height: 70,
      child: BottomNavigationBar(
currentIndex: _currentIndex,
  onTap: _onTabTapped,
  backgroundColor: GlobalStyles.bottomNavBarTheme.backgroundColor,
  selectedItemColor: GlobalStyles.bottomNavBarTheme.selectedItemColor, // Color de ítem seleccionado
  unselectedItemColor: GlobalStyles.bottomNavBarTheme.unselectedItemColor, // Color de ítem no seleccionado
  type: BottomNavigationBarType.fixed, // Tipo de barra (fija o shifting)
  showUnselectedLabels: true, // Mostrar etiquetas para los no seleccionados
  showSelectedLabels: true, // Mostrar etiquetas para los seleccionados

  // Estilos de íconos
  selectedIconTheme: IconThemeData(
    size: 30, // Tamaño de los íconos seleccionados
  ),
  unselectedIconTheme: IconThemeData(
    size: 24, // Tamaño de los íconos no seleccionados
  ),

  // Estilos de texto (labels)
  selectedLabelStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
  unselectedLabelStyle: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  ),

  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: "Historial",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: "Entrenamiento",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Perfil",
    ),
  ],
),
    ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _cancelMinimizedRoutine(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("¿Cancelar rutina?"),
          content: Text("¿Realmente quieres cancelar la rutina en ejecución?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.cancelMinimizedRoutine(); // Elimina la rutina minimizada
                Navigator.of(context).pop();
              },
              child: Text("Sí"),
            ),
          ],
        );
      },
    );
  }
}
