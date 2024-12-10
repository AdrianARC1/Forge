import 'package:flutter/material.dart';
import 'routine_form.dart';
import '../../app_state.dart';
import 'package:provider/provider.dart';

class EditRoutineScreen extends StatelessWidget {
  final Routine routine;

  const EditRoutineScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return RoutineForm(
      routine: routine,
      title: 'Editar Rutina',
      onSave: (Routine editedRoutine) async {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.updateRoutine(editedRoutine);
        Navigator.pop(context);
      },
      onCancel: () {
        Navigator.pop(context);
      },
    );
  }
}
