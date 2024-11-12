// main.dart
import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'screens/auth/login_screen.dart';
// Importa la librería para manejar la splash screen nativa
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mantener la splash screen nativa hasta que la aplicación esté lista
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

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
          // Una vez que la aplicación ya no está cargando, remover la splash screen nativa
          if (!appState.isLoading) {
            FlutterNativeSplash.remove();
          }

          return MaterialApp(
            title: 'Forge',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: appState.isLoading
                ? Container() // Pantalla vacía mientras carga
                : appState.userId == null
                    ? LoginScreen()
                    : MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
