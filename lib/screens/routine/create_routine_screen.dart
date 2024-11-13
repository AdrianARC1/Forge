// lib/screens/routine/create_routine_screen.dart
import 'package:flutter/material.dart';
import 'routine_form.dart';
import '../../app_state.dart';
import 'package:provider/provider.dart';

class CreateRoutineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RoutineForm(
      title: 'Crear Rutina',
      onSave: (Routine newRoutine) async {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.saveRoutine(newRoutine);
        Navigator.pop(context);
      },
      onCancel: () {
        Navigator.pop(context);
      },
    );
  }
}
