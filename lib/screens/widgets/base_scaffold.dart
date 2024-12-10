import 'package:flutter/material.dart';
import '../../styles/global_styles.dart';

class BaseScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const BaseScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      backgroundColor: backgroundColor ?? GlobalStyles.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
