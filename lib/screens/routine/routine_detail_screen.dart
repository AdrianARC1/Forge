// lib/screens/routine/routine_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../widgets/exercise_form_widget.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/app_bar_button.dart';
import '../../styles/global_styles.dart';
import 'routine_execution_screen.dart';
import 'edit_routine_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Routine routine;
  final bool isFromHistory;

  RoutineDetailScreen({
    required this.routine,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final Duration duration = routine.duration;
    final int totalVolume = routine.totalVolume;
    final DateTime? completionDate = routine.dateCompleted;

    return BaseScaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalStyles.backgroundColor,
        elevation: 0,
        leadingWidth: 60,
        title: Text(
          routine.name,
          style: GlobalStyles.insideAppTitleStyle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: GlobalStyles.textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: isFromHistory
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRoutineScreen(routine: routine),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Editar Rutina'),
                      ),
                    ];
                  },
                ),
              ]
            : [
                AppBarButton(
                  text: 'Comenzar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutineExecutionScreen(routine: routine),
                      ),
                    );
                  },
                  textColor: GlobalStyles.buttonTextStyle.color,
                  backgroundColor: GlobalStyles.backgroundButtonsColor,
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isFromHistory) ...[
                  SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/icon/icon.png'),
                        ),
                        SizedBox(height: 8),
                        Text(
                          appState.username ?? 'Usuario',
                          style: GlobalStyles.subtitleStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(completionDate ?? DateTime.now()),
                          style: GlobalStyles.subtitleStyle.copyWith(
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    routine.name,
                    style: GlobalStyles.subtitleStyleHighFont,
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: GlobalStyles.inputBorderColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: Offset(0, 5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (isFromHistory) ...[
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Duración
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duración',
                              style: GlobalStyles.subtitleStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: GlobalStyles.subtitleStyle,
                            ),
                          ],
                        ),
                        // Volumen total
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volumen',
                              style: GlobalStyles.subtitleStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$totalVolume kg',
                              style: GlobalStyles.subtitleStyle,
                            ),
                          ],
                        ),
                        // RPE medio
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RPE Medio',
                              style: GlobalStyles.subtitleStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _calculateAverageRPE(routine).toStringAsFixed(1),
                              style: GlobalStyles.subtitleStyle,
                            ),
                          ],
                        ),
                        // Total de series
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Series',
                              style: GlobalStyles.subtitleStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_calculateTotalSeries(routine)}',
                              style: GlobalStyles.subtitleStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    children: [
                      if (isFromHistory)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Entrenamiento',
                            style: GlobalStyles.subtitleStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      SizedBox(height: 8),
                      ...routine.exercises.map((exercise) {
                        final maxRecord = appState.maxExerciseRecords[exercise.name];

                        return ExerciseFormWidget(
                          exercise: Exercise(
                            id: exercise.id,
                            name: exercise.name,
                            gifUrl: exercise.gifUrl,
                            series: exercise.series,
                          ),
                          weightControllers: {},
                          repsControllers: {},
                          exertionControllers: {},
                          isExecution: false,
                          isReadOnly: true,
                          maxRecord: maxRecord,
                          allowEditing: false,
                          showMaxRecord: !isFromHistory,
                        );
                      }).toList(),
                    ],
                  ),
                ),
                if (isFromHistory && routine.notes != null && routine.notes!.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Notas',
                      style: GlobalStyles.subtitleStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      routine.notes!,
                      style: GlobalStyles.subtitleStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String weekday = _getWeekday(date.weekday);
    String month = _getMonth(date.month);
    String day = date.day.toString();
    String year = date.year.toString();
    String time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$weekday, $month $day, $year - $time';
  }

  String _getWeekday(int weekday) {
    List<String> weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
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
    return months[month - 1];
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
      return '${minutesStr}${secondsStr}'.trim();
    }
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
