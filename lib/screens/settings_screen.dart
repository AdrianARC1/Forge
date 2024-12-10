import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/global_styles.dart';
import './widgets/base_scaffold.dart';
import '../app_state.dart';
import 'auth/login_screen.dart';
import 'onboarding/intro_slides.dart';
import './widgets/custom_alert_dialog.dart';

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
    final appState = Provider.of<AppState>(context);

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Ajustes', style: GlobalStyles.insideAppTitleStyle),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: GlobalStyles.textColor,
            size: 24.0,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Atrás',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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

            const Spacer(),

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  // Mostrar un diálogo de confirmación con fondo difuminado usando la función personalizada
                  bool? confirm = await showCustomAlertDialog<bool>(
                    context: context,
                    title: 'Cerrar Sesión',
                    content: const Text(
                      '¿Estás seguro de que deseas cerrar sesión?',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  );

                  if (confirm == true) {
                    await appState.logout();
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
