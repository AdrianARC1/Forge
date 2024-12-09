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
              child: Container(
                color: GlobalStyles.navigationBarColor, // Fondo igual que la barra de navegación
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Para que la columna ocupe el espacio mínimo
                  children: [
                    // Nombre de la rutina centrado
                    Text(
                      "${appState.minimizedRoutine!.name}",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    // Temporizador centrado
                    Text(
                      _formatDuration(appState.minimizedRoutineDuration),
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.0), // Espacio entre el temporizador y los botones
                    // Fila con los dos botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botón "Descartar"
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent, // Sin fondo
                          ),
                          onPressed: () => _cancelMinimizedRoutine(context),
                          icon: Icon(Icons.close, color: Colors.red, size: 26,),
                          label: Text(
                            'Descartar',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),

                        // Botón "Volver a la rutina"
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent, // Sin fondo
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoutineExecutionScreen(routine: appState.minimizedRoutine),
                              ),
                            );
                          },
                          icon: Icon(Icons.play_arrow, color: GlobalStyles.backgroundButtonsColor, size: 26),
                          label: Text(
                            'Volver a la rutina',
                            style: TextStyle(color: GlobalStyles.backgroundButtonsColor, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory, // Desactiva el splash
            highlightColor: Colors.transparent,    // Asegura que no haya highlight
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: GlobalStyles.bottomNavBarTheme.backgroundColor,
            selectedItemColor: GlobalStyles.backgroundButtonsColor, // Color de ítem seleccionado
            unselectedItemColor: GlobalStyles.bottomNavBarTheme.unselectedItemColor, // Color de ítem no seleccionado
            type: BottomNavigationBarType.fixed, // Tipo de barra (fija o shifting)
            showUnselectedLabels: true, // Mostrar etiquetas para los no seleccionados
            showSelectedLabels: true, // Mostrar etiquetas para los seleccionados

            // Estilos de íconos
            selectedIconTheme: IconThemeData(
              size: 32, // Tamaño de los íconos seleccionados
              color: GlobalStyles.backgroundButtonsColor, // Asegura el color del ícono seleccionado
            ),
            unselectedIconTheme: IconThemeData(
              size: 24, // Tamaño de los íconos no seleccionados
              color: GlobalStyles.bottomNavBarTheme.unselectedItemColor, // Color de íconos no seleccionados
            ),

            // Estilos de texto (labels)
            selectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GlobalStyles.backgroundButtonsColor, // Color de la etiqueta seleccionada
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: GlobalStyles.bottomNavBarTheme.unselectedItemColor, // Color de la etiqueta no seleccionada
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
