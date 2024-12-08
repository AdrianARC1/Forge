// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de importar Provider
import '../styles/global_styles.dart';
import './widgets/base_scaffold.dart';
import './widgets/app_bar_button.dart';
import '../app_state.dart'; // Importa AppState para acceder al estado de la aplicación
import 'auth/login_screen.dart'; // Importa LoginScreen para la navegación

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Accede al estado de la aplicación

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Ajustes', style: GlobalStyles.insideAppTitleStyle),
        leading: AppBarButton(
          text: 'Atrás',
          onPressed: () => Navigator.pop(context),
          textColor: GlobalStyles.textColor,
          backgroundColor: Colors.transparent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0), // Agrega padding para mejor espaciado
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Modo Oscuro', style: TextStyle(color: GlobalStyles.textColor)),
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                  // Aquí puedes agregar lógica para cambiar el tema de la aplicación
                });
              },
              activeColor: GlobalStyles.backgroundButtonsColor,
            ),
            SwitchListTile(
              title: Text('Notificaciones', style: TextStyle(color: GlobalStyles.textColor)),
              value: _notifications,
              onChanged: (value) {
                setState(() {
                  _notifications = value;
                  // Aquí puedes agregar lógica para manejar las notificaciones
                });
              },
              activeColor: GlobalStyles.backgroundButtonsColor,
            ),
            SizedBox(height: 16),
            Text(
              'Aquí puedes configurar las opciones de la aplicación.',
              style: TextStyle(color: GlobalStyles.textColorWithOpacity),
            ),

            Spacer(), // Empuja el botón de cerrar sesión al final

            Divider(color: GlobalStyles.textColorWithOpacity), // Separador visual
            SizedBox(height: 16),

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // Color destacado para cerrar sesión
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  // Opcional: Mostrar un diálogo de confirmación
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Cerrar Sesión'),
                      content: Text('¿Estás seguro de que deseas cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Cerrar Sesión'),
                        ),
                      ],
                    ),
                  );

                  if (confirm) {
                    await appState.logout(); // Llama al método de logout
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
