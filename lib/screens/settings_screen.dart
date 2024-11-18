// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Cambiar Contraseña'),
            onTap: () {
              // Implementa la lógica para cambiar la contraseña
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          SwitchListTile(
            title: Text('Habilitar Notificaciones'),
            value: appState.notificationsEnabled,
            onChanged: (bool value) {
              appState.setNotificationsEnabled(value);
            },
          ),
          // Añade más opciones según tus necesidades
        ],
      ),
    );
  }
}
