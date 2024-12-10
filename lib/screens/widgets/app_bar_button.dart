// lib/widgets/app_bar_button.dart

import 'package:flutter/material.dart';
import 'package:forge/styles/global_styles.dart';

class AppBarButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AppBarButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 0.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor, // Eliminado el valor por defecto
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          minimumSize: const Size(50, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GlobalStyles.buttonTextStyle.copyWith(
            color: textColor ?? GlobalStyles.buttonTextStyle.color,
          ),
        ),
      ),
    );
  }
}
