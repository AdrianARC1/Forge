// lib/screens/tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../navigation/main_navigation_screen.dart';

class TutorialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Tutorial')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '¡Bienvenido a Forge!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Aquí puedes crear y gestionar tus rutinas de entrenamiento.',
              style: TextStyle(fontSize: 16),
            ),
            // Agrega más contenido del tutorial según necesites
            Spacer(),
            ElevatedButton(
              onPressed: () {
                appState.completeTutorial();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainNavigationScreen()),
                );
              },
              child: Text('Comenzar a usar la app'),
            ),
          ],
        ),
      ),
    );
  }
}
