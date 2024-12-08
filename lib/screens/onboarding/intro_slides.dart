// lib/screens/onboarding/intro_slides.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../navigation/main_navigation_screen.dart';
import '../../styles/global_styles.dart';

class IntroSlides extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Bienvenido a Forge",
          body: "Organiza tus rutinas de entrenamiento de manera sencilla y efectiva.",
          image: Center(child: Image.asset('assets/icon/icon.png', height: 175.0)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
            bodyTextStyle: TextStyle(fontSize: 18.0, color: GlobalStyles.textColor),
            pageColor: GlobalStyles.backgroundColor,
          ),
        ),
        PageViewModel(
          title: "Crea Rutinas Personalizadas",
          body: "Diseña rutinas diarias, semanales o mensuales adaptadas a tus necesidades.",
          image: Center(child: Image.asset('assets/icon/icon.png', height: 175.0)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
            bodyTextStyle: TextStyle(fontSize: 18.0, color: GlobalStyles.textColor),
            pageColor: GlobalStyles.backgroundColor,
          ),
        ),
        PageViewModel(
          title: "Seguimiento de Progreso",
          body: "Monitorea tu rendimiento y alcanza tus objetivos de fitness.",
          image: Center(child: Image.asset('assets/icon/icon.png', height: 175.0)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
            bodyTextStyle: TextStyle(fontSize: 18.0, color: GlobalStyles.textColor),
            pageColor: GlobalStyles.backgroundColor,
          ),
        ),
      ],
      onDone: () async {
        await appState.completeTutorial();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigationScreen()),
        );
      },
      onSkip: () async {
        await appState.completeTutorial();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigationScreen()),
        );
      },
      showSkipButton: true,
      skip: const Text('Saltar', style: TextStyle(color: GlobalStyles.backgroundButtonsColor)),
      next: const Icon(Icons.arrow_forward, color: GlobalStyles.backgroundButtonsColor),
      done: const Text("Comenzar", style: TextStyle(fontWeight: FontWeight.w600, color: GlobalStyles.backgroundButtonsColor)),
      dotsDecorator: const DotsDecorator(
        activeColor: GlobalStyles.backgroundButtonsColor,
        size: Size(10.0, 10.0),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      globalBackgroundColor: GlobalStyles.backgroundColor,
    );
  }
}
