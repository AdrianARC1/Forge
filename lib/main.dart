import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/main_navigation_screen.dart'; // Importa la pantalla de navegación principal

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'Forge',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: MainNavigationScreen(), // Cambia a la pantalla de navegación principal
      ),
    );
  }
}
