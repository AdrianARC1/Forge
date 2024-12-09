// lib/screens/routine/routine_summary_screen.dart

import 'package:flutter/material.dart';
import '../../../app_state.dart';
import '../widgets/base_scaffold.dart';
import '../../styles/global_styles.dart';

class RoutineSummaryScreen extends StatefulWidget {
  final Routine routine;
  final Duration duration;
  final VoidCallback onDiscard;
  final VoidCallback onResume;
  final void Function(Routine updatedRoutine) onSave; // se cambia a aceptar un Routine

  const RoutineSummaryScreen({super.key, 
    required this.routine,
    required this.duration,
    required this.onDiscard,
    required this.onResume,
    required this.onSave,
  });

  @override
  _RoutineSummaryScreenState createState() => _RoutineSummaryScreenState();
}

class _RoutineSummaryScreenState extends State<RoutineSummaryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _notesController = TextEditingController(text: widget.routine.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Duration duration = widget.duration;
    final int totalVolume = _calculateTotalVolume(widget.routine);
    final double averageRPE = _calculateAverageRPE(widget.routine);
    final int totalSeries = _calculateTotalSeries(widget.routine);
    final DateTime now = widget.routine.dateCompleted ?? DateTime.now();

    return BaseScaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        leadingWidth: 100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlobalStyles.textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Resumen de Rutina',
          style: GlobalStyles.insideAppTitleStyle,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nombre de la rutina (editable)
                TextField(
                  controller: _nameController,
                  style: GlobalStyles.subtitleStyleHighFont.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: "Nombre de la rutina",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20.0),
                  height: 2,
                  decoration: BoxDecoration(
                    color: GlobalStyles.inputBorderColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(0, 5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Datos en fila
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _dataColumn('Duración', _formatDuration(duration)),
                      const SizedBox(width: 20),
                      _dataColumn('Volumen', '$totalVolume kg'),
                      const SizedBox(width: 20),
                      _dataColumn('RPE Medio', averageRPE.toStringAsFixed(1)),
                      const SizedBox(width: 20),
                      _dataColumn('Total Series', '$totalSeries'),
                      const SizedBox(width: 20),
                      _dataColumn('Fecha', _formatDate(now)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'Notas:',
                  style: GlobalStyles.subtitleStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  style: GlobalStyles.subtitleStyle,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Añade notas sobre tu entrenamiento...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: GlobalStyles.inputBackgroundColor,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: GlobalStyles.inputBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: GlobalStyles.inputBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: GlobalStyles.focusedBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedRoutine = widget.routine.copyWith(
                        name: _nameController.text.trim(),
                        notes: _notesController.text.trim(),
                      );
                      widget.onSave(updatedRoutine);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalStyles.backgroundButtonsColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Guardar Rutina', style: GlobalStyles.buttonTextStyle),
                  ),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2d2d2d),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Volver a la Rutina', style: GlobalStyles.buttonTextStyleLight),
                  ),
                ),

                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: widget.onDiscard,
                    child: const Text(
                      'Descartar Entrenamiento',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dataColumn(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: GlobalStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GlobalStyles.subtitleStyle),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      String hoursStr = '${hours}h';
      String minutesStr = minutes > 0 ? ' ${minutes}min' : '';
      return '$hoursStr$minutesStr';
    } else {
      String minutesStr = minutes > 0 ? '${minutes}min' : '';
      String secondsStr = seconds > 0 ? ' ${seconds}s' : '';
      return '$minutesStr$secondsStr'.trim();
    }
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    String month = months[date.month - 1];
    String day = date.day.toString();
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  int _calculateTotalVolume(Routine routine) {
    int totalVolume = 0;
    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalVolume += series.weight * series.reps;
      }
    }
    return totalVolume;
  }

  double _calculateAverageRPE(Routine routine) {
    int totalRPE = 0;
    int count = 0;
    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalRPE += series.perceivedExertion;
        count++;
      }
    }
    return count > 0 ? totalRPE / count : 0.0;
  }

  int _calculateTotalSeries(Routine routine) {
    int totalSeries = 0;
    for (var exercise in routine.exercises) {
      totalSeries += exercise.series.length;
    }
    return totalSeries;
  }
}
