import 'package:flutter/material.dart';
import 'package:forge/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../routine/routine_list_screen.dart';
import '../history_screen.dart';
import '../routine/routine_execution_screen.dart';
import '../../styles/global_styles.dart';
import '../widgets/custom_alert_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const HistoryScreen(),
    const RoutineListScreen(),
    const ProfileScreen(),
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
      backgroundColor: GlobalStyles.backgroundColor,
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (appState.minimizedRoutine != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: GlobalStyles.navigationBarColor,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appState.minimizedRoutine!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _formatDuration(appState.minimizedRoutineDuration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                          onPressed: () => _cancelMinimizedRoutine(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 26,
                          ),
                          label: const Text(
                            'Descartar',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Botón "Volver a la rutina"
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoutineExecutionScreen(routine: appState.minimizedRoutine),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.play_arrow,
                            color: GlobalStyles.backgroundButtonsColor,
                            size: 26,
                          ),
                          label: const Text(
                            'Volver a la rutina',
                            style: TextStyle(
                              color: GlobalStyles.backgroundButtonsColor,
                              fontSize: 14,
                            ),
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
      bottomNavigationBar: SizedBox(
        height: 70,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: GlobalStyles.bottomNavBarTheme.backgroundColor,
            selectedItemColor: GlobalStyles.backgroundButtonsColor,
            unselectedItemColor: GlobalStyles.bottomNavBarTheme.unselectedItemColor,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            showSelectedLabels: true,

            // Estilos de íconos
            selectedIconTheme: const IconThemeData(
              size: 32,
              color: GlobalStyles.backgroundButtonsColor,
            ),
            unselectedIconTheme: IconThemeData(
              size: 24,
              color: GlobalStyles.bottomNavBarTheme.unselectedItemColor,
            ),

            // Estilos de texto (labels)
            selectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: GlobalStyles.backgroundButtonsColor,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: GlobalStyles.bottomNavBarTheme.unselectedItemColor,
            ),

            items: const [
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

  Future<void> _cancelMinimizedRoutine(BuildContext context) async {
    bool? confirm = await showCustomAlertDialog<bool>(
      context: context,
      title: '¿Cancelar rutina?',
      content: const Text(
        '¿Realmente quieres cancelar la rutina en ejecución?',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Sí"),
        ),
      ],
    );

    if (confirm == true) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.cancelMinimizedRoutine();
    }
  }
}
