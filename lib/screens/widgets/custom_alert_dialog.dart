import 'dart:ui';
import 'package:flutter/material.dart';
import '../../styles/global_styles.dart';

Future<T?> showCustomAlertDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: title,
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, anim1, anim2) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Capa de desenfoque de fondo
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            // Diálogo centrado
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: GlobalStyles.inputBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GlobalStyles.subtitleStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    content,
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
