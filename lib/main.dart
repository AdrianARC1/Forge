// main.dart
import 'package:flutter/material.dart';
import 'package:forge/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import './styles/global_styles.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding/intro_slides.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();

  // Mantener la splash screen nativa hasta que la aplicación esté lista
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  // await DatabaseHelper().resetDatabase();
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
            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: GlobalStyles.backgroundColor,
              bottomNavigationBarTheme: GlobalStyles.bottomNavBarTheme,
              appBarTheme: AppBarTheme(
                backgroundColor: GlobalStyles.navigationBarColor,
                centerTitle: true,
                foregroundColor: Colors.white,
              ),
            ),
            home: appState.isLoading
                ? Container() // Pantalla vacía mientras carga
                : appState.hasSeenTutorial
                    ? (appState.userId == null ? LoginScreen() : MainNavigationScreen())
                    : IntroSlides(), // Mostrar el tutorial si no se ha visto
          );
        },
      ),
    );
  }
}
