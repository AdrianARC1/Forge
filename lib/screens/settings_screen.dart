// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de importar Provider
import '../styles/global_styles.dart';
import './widgets/base_scaffold.dart';
import '../app_state.dart'; // Importa AppState para acceder al estado de la aplicación
import 'auth/login_screen.dart'; // Importa LoginScreen para la navegación
import 'onboarding/intro_slides.dart'; // Importa IntroSlides para el tutorial

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
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
        title: const Text('Ajustes', style: GlobalStyles.insideAppTitleStyle),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back, // Ícono de flecha de retroceso
            color: GlobalStyles.textColor, // Color personalizado
            size: 24.0, // Tamaño del ícono (puedes ajustarlo según tus necesidades)
          ),
          onPressed: () => Navigator.pop(context), // Acción al presionar
          tooltip: 'Atrás', // Descripción para accesibilidad
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0), // Ajuste de padding para mejor espaciado
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferencias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GlobalStyles.textColor,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Modo Oscuro', style: TextStyle(color: GlobalStyles.textColor)),
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                  // Aquí puedes agregar lógica para cambiar el tema de la aplicación
                  // Por ejemplo: appState.toggleDarkMode(value);
                });
              },
              activeColor: GlobalStyles.backgroundButtonsColor,
            ),
            SwitchListTile(
              title: const Text('Notificaciones', style: TextStyle(color: GlobalStyles.textColor)),
              value: _notifications,
              onChanged: (value) {
                setState(() {
                  _notifications = value;
                  // Aquí puedes agregar lógica para manejar las notificaciones
                  // Por ejemplo: appState.toggleNotifications(value);
                });
              },
              activeColor: GlobalStyles.backgroundButtonsColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aquí puedes configurar las opciones de la aplicación.',
              style: TextStyle(color: GlobalStyles.textColorWithOpacity),
            ),
            const SizedBox(height: 32),

            // Botón para Ver el Tutorial
            ListTile(
              leading: const Icon(Icons.info_outline, color: GlobalStyles.textColor),
              title: const Text(
                'Ver Tutorial',
                style: TextStyle(color: GlobalStyles.textColor, fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: GlobalStyles.textColorWithOpacity),
              onTap: () async {
                // Reiniciar el estado del tutorial
                await appState.resetTutorial();

                // Navegar a la pantalla de introducción
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IntroSlides()),
                );
              },
            ),
            const Divider(color: GlobalStyles.textColorWithOpacity),
            const SizedBox(height: 16),

            const Spacer(), // Empuja el botón de cerrar sesión al final

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // Color destacado para cerrar sesión
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  // Opcional: Mostrar un diálogo de confirmación
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar Sesión'),
                      content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Cerrar Sesión'),
                        ),
                      ],
                    ),
                  );

                  if (confirm) {
                    await appState.logout(); // Llama al método de logout
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
