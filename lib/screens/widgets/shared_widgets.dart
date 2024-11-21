import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';
import '../../styles/global_styles.dart';

class ClipPad extends CustomClipper<Rect> {
  final EdgeInsets padding;

  const ClipPad({
    this.padding = EdgeInsets.zero,
  });

  @override
  Rect getClip(Size size) => padding.inflateRect(Offset.zero & size);

  @override
  bool shouldReclip(ClipPad oldClipper) => oldClipper.padding != padding;
}

class SharedWidgets {
  static Widget buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? prefixIcon,
  }) {
    return ClipRect(
      clipper: const ClipPad(
        padding: EdgeInsets.only(left: 10, top: 30),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: GlobalStyles.inputBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.40),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 10),
              inset: true,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(0, 10),
              blurRadius: 10,
              spreadRadius: 0,
              inset: true,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(10, 10),
              inset: true,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(-10, 0),
              inset: true,
            ),
          ],
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
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
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
      ),
    );
  }

  /// Widget compartido para el botón primario
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool enabled = true,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: GlobalStyles.buttonColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
