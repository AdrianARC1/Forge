import 'package:flutter/material.dart';
import '../../styles/global_styles.dart';

class SharedWidgets {
  /// Widget compartido para campos de texto con validación
  static Widget buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: GlobalStyles.inputBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          labelText: labelText,
          labelStyle: TextStyle(
            color: GlobalStyles.placeholderColor,
          ),
          errorStyle: GlobalStyles.errorTextStyle,
          border: InputBorder.none, // No border en estado normal
          focusedBorder: InputBorder.none, // No border al enfocar
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: GlobalStyles.errorBorderColor, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: GlobalStyles.errorBorderColor, width: 2),
          ),
        ),
        style: TextStyle(color: GlobalStyles.textColor),
        textInputAction: textInputAction,
      ),
    );
  }

  /// Widget compartido para el botón primario
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: GlobalStyles.buttonColor,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: enabled ? onPressed : null,
      child: isLoading
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(GlobalStyles.backgroundColor),
            )
          : Text(
              text,
              style: GlobalStyles.buttonTextStyle,
            ),
    );
  }

  /// Widget compartido para botones de enlace (links)
  static Widget buildLinkButton({
    required String text,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      child: Text(
        text,
        style: GlobalStyles.linkTextStyle,
      ),
    );
  }
}
