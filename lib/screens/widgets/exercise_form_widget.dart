// lib/screens/widgets/exercise_form_widget.dart
import 'package:flutter/material.dart';
import '../../app_state.dart';

class ExerciseFormWidget extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onAddSeries;
  final Function(int) onDeleteSeries;
  final Map<String, TextEditingController> weightControllers;
  final Map<String, TextEditingController> repsControllers;
  final Map<String, TextEditingController> exertionControllers;
  final bool isExecution;
  final VoidCallback? onDeleteExercise;
  final Future<void> Function()? onReplaceExercise;
  final Function(Series)? onAutofillSeries;

  ExerciseFormWidget({
    required this.exercise,
    required this.onAddSeries,
    required this.onDeleteSeries,
    required this.weightControllers,
    required this.repsControllers,
    required this.exertionControllers,
    this.isExecution = false,
    this.onDeleteExercise,
    this.onReplaceExercise,
    this.onAutofillSeries,
  });

  @override
  _ExerciseFormWidgetState createState() => _ExerciseFormWidgetState();
}

class _ExerciseFormWidgetState extends State<ExerciseFormWidget> {
  @override
  Widget build(BuildContext context) {
    // Determinar si mostrar el campo de RIR y la casilla de verificación
    bool showRIRAndCheckbox = widget.isExecution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(widget.exercise.name),
          subtitle: widget.isExecution ? Text("Series: ${widget.exercise.series.length}") : null,
          trailing: widget.isExecution
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      widget.onDeleteExercise?.call();
                    } else if (value == 'replace') {
                      widget.onReplaceExercise?.call();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar Ejercicio'),
                      ),
                      PopupMenuItem(
                        value: 'replace',
                        child: Text('Reemplazar Ejercicio'),
                      ),
                    ];
                  },
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(child: Center(child: Text("SERIE"))),
              if (widget.isExecution)
                Expanded(child: Center(child: Text("ANTERIOR")))
              else
                SizedBox(),
              Expanded(child: Center(child: Text("KG"))),
              Expanded(child: Center(child: Text("REPS"))),
              if (showRIRAndCheckbox)
                Expanded(child: Center(child: Text("RIR")))
              else
                SizedBox(),
              if (showRIRAndCheckbox)
                Expanded(child: Center(child: Icon(Icons.check)))
              else
                SizedBox(),
            ],
          ),
        ),
Column(
          children: widget.exercise.series.asMap().entries.map((entry) {
            int seriesIndex = entry.key;
            Series series = entry.value;

            return Dismissible(
              key: ValueKey(series.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) => widget.onDeleteSeries(seriesIndex),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
                child: Row(
                  children: [
                    Expanded(child: Center(child: Text("${seriesIndex + 1}"))),
                    if (widget.isExecution)
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              if (widget.onAutofillSeries != null) {
                                widget.onAutofillSeries!(series);
                              }
                            },
                            child: Text(
                              "${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: widget.weightControllers[series.id],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: widget.isExecution && series.previousWeight != null
                                ? series.previousWeight.toString()
                                : 'KG',
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            series.weight = int.tryParse(value) ?? 0;
                            // No llamamos a setState aquí
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: widget.repsControllers[series.id],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: widget.isExecution && series.previousReps != null
                                ? series.previousReps.toString()
                                : 'Reps',
                            hintStyle: TextStyle(color: Colors.grey),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            series.reps = int.tryParse(value) ?? 0;
                            // No llamamos a setState aquí
                          },
                        ),
                      ),
                    ),
                    if (showRIRAndCheckbox)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DropdownButton<int>(
                            value: series.perceivedExertion > 0 ? series.perceivedExertion : null,
                            isExpanded: true,
                            alignment: Alignment.center,
                            hint: Center(
                              child: Text(
                                widget.isExecution && series.lastSavedPerceivedExertion != null
                                    ? series.lastSavedPerceivedExertion.toString()
                                    : 'RIR',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            items: List.generate(10, (index) => index + 1).map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(value.toString()),
                                ),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                series.perceivedExertion = newValue ?? 0;
                              });
                            },
                          ),
                        ),
                      )
                    else
                      SizedBox(),
                    if (showRIRAndCheckbox)
                      Expanded(
                        child: Center(
                          child: Checkbox(
                            value: series.isCompleted,
                            onChanged: (value) {
                              setState(() {
                                if (value == true && widget.isExecution && widget.onAutofillSeries != null) {
                                  widget.onAutofillSeries!(series);
                                }
                                series.isCompleted = value ?? false;
                              });
                            },
                          ),
                        ),
                      )
                    else
                      SizedBox(),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            onPressed: widget.onAddSeries,
            child: Text("+ Agregar Serie"),
          ),
        ),
        Divider(),
      ],
    );
  }
}
