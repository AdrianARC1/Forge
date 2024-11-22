import 'package:flutter/material.dart';
import '../../styles/global_styles.dart'; // Asegúrate de que la ruta es correcta

class BaseScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation; // Nuevo parámetro
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor; // Nuevo parámetro opcional

  const BaseScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation, // Inicialización del nuevo parámetro
    this.drawer,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor, // Inicialización del nuevo parámetro
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      backgroundColor: backgroundColor ?? GlobalStyles.backgroundColor, // Uso del backgroundColor si se proporciona
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10), // Padding general
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation, // Pasar el parámetro al Scaffold
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
