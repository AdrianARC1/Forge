// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Puedes personalizar el fondo como desees
      backgroundColor: Colors.white,
      body: Center(
        // Aquí puedes colocar tu logo o un widget de carga
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o imagen de la app
            // Si no tienes un logo aún, puedes usar un Icon temporalmente
            Icon(
              Icons.fitness_center,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            // Indicador de progreso
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
