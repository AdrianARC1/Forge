// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../styles/global_styles.dart';
import './widgets/base_scaffold.dart';
import './widgets/app_bar_button.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferencias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text('Modo Oscuro', style: TextStyle(color: GlobalStyles.textColor)),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
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
              });
            },
            activeColor: GlobalStyles.backgroundButtonsColor,
          ),
          SizedBox(height: 16),
          Text(
            'Aquí puedes configurar las opciones de la aplicación.',
            style: TextStyle(color: GlobalStyles.textColorWithOpacity),
          ),
        ],
      ),
    );
  }
}
