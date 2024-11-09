// main.dart
import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/splash_screen.dart'; // Importa el SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Llama a resetDatabase para eliminar los datos de la base de datos
  // await DatabaseHelper().resetDatabase();
  // print("Base de datos reiniciada.");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Forge',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: appState.isLoading
                ? SplashScreen()
                : appState.userId == null
                    ? LoginScreen()
                    : MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
