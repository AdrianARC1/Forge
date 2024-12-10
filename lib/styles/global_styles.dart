import 'package:flutter/material.dart';

class GlobalStyles {
  // Colores
  static const Color backgroundColor = Color(0xFF373737);
  static const Color navigationBarColor = Color(0xFF262626); // Color de fondo de la barra de navegación
  static const Color navigationBarIconColor = Colors.white; // Color de los iconos y texto
  static const Color buttonColor = Color(0xFFC3C3C3);
  static const Color textColor = Colors.white;
  static const Color textColorWithOpacity = Color.fromARGB(60, 255, 255, 255);
  static const Color placeholderColor = Colors.white54;
  static const Color errorColor = Colors.red;
  static const Color inputBackgroundColor = Color(0xFF2D2D2D);
  static const Color focusedBorderColor = Colors.blueAccent;
  static const Color errorBorderColor = Colors.redAccent;
  static const Color backgroundButtonsColor = Color(0xFFFFAA76);
  static const Color inputBorderColor = Colors.grey; // Color del borde inferior cuando está habilitado

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: textColor,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 4,
  );

  static const TextStyle insideAppTitleStyle = TextStyle(
    color: textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    color: textColor,
    fontSize: 16,
  );

    static const TextStyle exerciseDataStyle = TextStyle(
    color: textColor,
    fontSize: 14,
  );
    static const TextStyle routineDataStyle = TextStyle(
    color: backgroundButtonsColor,
    fontSize: 16,
  );

  static const TextStyle subtitleStyleRoutineData = TextStyle(
    color: textColor,
    fontSize: 14,
  );
    static const TextStyle orangeSubtitleStyle = TextStyle(
    color: backgroundButtonsColor,
    fontSize: 18,
  );

  static const TextStyle subtitleStyleHighFont = TextStyle(
    color: textColorWithOpacity,
    fontSize: 26,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Color(0xFF000000),
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonTextStyleLight = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle linkTextStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const TextStyle errorTextStyle = TextStyle(
    color: errorColor,
    fontSize: 14,
  );

  static const TextStyle lowSubtitleStyle = TextStyle(
    color: textColor,
    fontSize: 14,
  );

  // Estilos para BottomNavigationBar
  static const BottomNavigationBarThemeData bottomNavBarTheme = BottomNavigationBarThemeData(
    backgroundColor: navigationBarColor,
    selectedItemColor: navigationBarIconColor,
    unselectedItemColor: navigationBarIconColor,
    // Puedes ajustar otros parámetros si lo deseas
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: true,
    showSelectedLabels: true,
    // Define estilos de texto si es necesario
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelStyle: TextStyle(
      fontWeight: FontWeight.normal,
    ),
  );
}
