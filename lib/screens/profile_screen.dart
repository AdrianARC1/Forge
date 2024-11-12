// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.username == null) {
      // Si el usuario no está autenticado, redirigir al inicio de sesión
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
      return Scaffold(); // Retorna un scaffold vacío mientras se redirige
    }

    int totalWorkouts = appState.completedRoutines.length;
    int totalVolume = appState.completedRoutines.fold<int>(0, (int sum, routine) {
      return sum + (routine.totalVolume);
    });

    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            SizedBox(height: 16),
            Text(
              appState.username ?? 'Usuario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('Rutinas Completadas'),
              trailing: Text('$totalWorkouts'),
            ),
            ListTile(
              leading: Icon(Icons.line_weight),
              title: Text('Volumen Total Levantado'),
              trailing: Text('$totalVolume kg'),
            ),
            // Puedes agregar más estadísticas si lo deseas
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await appState.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              },
              child: Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
