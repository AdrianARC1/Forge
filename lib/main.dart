import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/main_navigation_screen.dart';
import 'database/database_helper.dart'; // Importa DatabaseHelper para acceder a resetDatabase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Llama a resetDatabase para eliminar los datos de la base de datos
  await DatabaseHelper().resetDatabase();
  print("Base de datos reiniciada.");

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
        home: MainNavigationScreen(),
      ),
    );
  }
}
