import 'package:flutter/material.dart';

class GlobalStyles {
  // Colores
  static const Color backgroundColor = Color(0xFF373737);
  static const Color buttonColor = Color(0xFFC3C3C3);
  static const Color textColor = Colors.white;
  static const Color placeholderColor = Colors.white54;
  static const Color errorColor = Colors.red;
  static const Color inputBackgroundColor = Color(0xFF2D2D2D);
  static const Color focusedBorderColor = Colors.blueAccent;
  static const Color errorBorderColor = Colors.redAccent; // Color para el borde de error

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: textColor,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 4,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: textColor,
    fontSize: 16,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Color(0xFF373737),
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
}