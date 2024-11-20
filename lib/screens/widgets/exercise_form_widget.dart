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
  // Mapa para almacenar los GlobalKeys de cada serie
  Map<String, GlobalKey> seriesRowKeys = {};

  // OverlayEntry activo
  OverlayEntry? activeOverlay;

  // Mapa para almacenar los valores temporales de RPE mientras se edita
  Map<String, double> tempRPEValues = {};

  // Mapa para almacenar los valores originales de RPE antes de editar
  Map<String, double> originalRPEValues = {};

  // ID de la serie que actualmente tiene el Slider activo
  String? activeSliderSeriesId;

  @override
  void initState() {
    super.initState();
    // Inicializar los GlobalKeys para cada serie
    for (var series in widget.exercise.series) {
      seriesRowKeys[series.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    // Asegurarse de eliminar cualquier OverlayEntry activo al destruir el widget
    activeOverlay?.remove();
    super.dispose();
  }

  void showRPEOverlay(BuildContext context, Series series) {
    // Remover cualquier Overlay existente
    activeOverlay?.remove();

    // Obtener la RenderBox del row de la serie
    RenderBox renderBox = seriesRowKeys[series.id]!.currentContext!.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);
    Size size = renderBox.size;

    // Crear el OverlayEntry
    activeOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 10, // 10 es un margen
        left: position.dx,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setOverlayState) {
                double currentValue = tempRPEValues[series.id] ??
                    (series.perceivedExertion > 0 ? series.perceivedExertion.toDouble() : 1.0);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: currentValue,
                      min: 1,
                      max: 10,
                      divisions: 9, // Pasos enteros de 1 a 10
                      label: currentValue.round().toString(),
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
                      onChanged: (double newValue) {
                        setOverlayState(() {
                          tempRPEValues[series.id] = newValue;
                          series.perceivedExertion = newValue.round();
                        });
                        // Llamar a setState del widget principal para actualizar el RPE Text
                        setState(() {});
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Cancelar: remover Overlay sin guardar cambios
                            activeOverlay?.remove();
                            activeOverlay = null;
                            setState(() {
                              // Revertir el valor de RPE a su valor original
                              if (originalRPEValues.containsKey(series.id)) {
                                series.perceivedExertion = originalRPEValues[series.id]!.round();
                                originalRPEValues.remove(series.id);
                              }
                              tempRPEValues.remove(series.id);
                              activeSliderSeriesId = null;
                            });
                          },
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Guardar: remover Overlay
                            activeOverlay?.remove();
                            activeOverlay = null;
                            setState(() {
                              // No es necesario revertir el valor ya que se actualizó en tiempo real
                              originalRPEValues.remove(series.id);
                              tempRPEValues.remove(series.id);
                              activeSliderSeriesId = null;
                            });
                          },
                          child: Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // Insertar el OverlayEntry en el Overlay
    Overlay.of(context)!.insert(activeOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si mostrar el campo de RPE y la casilla de verificación
    bool showRPEAndCheckbox = widget.isExecution;

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
              if (showRPEAndCheckbox)
                Expanded(child: Center(child: Text("RPE")))
              else
                SizedBox(),
              if (showRPEAndCheckbox)
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

            bool isActive = activeSliderSeriesId == series.id;
            double currentRPE = tempRPEValues[series.id]?.toDouble() ?? series.perceivedExertion.toDouble();

            return Padding(
              key: seriesRowKeys[series.id], // Asignar un GlobalKey único
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
                  if (showRPEAndCheckbox)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isActive) {
                              // Cerrar el Slider y guardar el valor
                              activeOverlay?.remove();
                              activeOverlay = null;
                              tempRPEValues.remove(series.id);
                              originalRPEValues.remove(series.id);
                              activeSliderSeriesId = null;
                            } else {
                              // Abrir el Slider
                              activeSliderSeriesId = series.id;
                              originalRPEValues[series.id] = series.perceivedExertion.toDouble();
                              tempRPEValues[series.id] = series.perceivedExertion > 0
                                  ? series.perceivedExertion.toDouble()
                                  : 1.0;
                              showRPEOverlay(context, series);
                            }
                          });
                        },
                        child: Text(
                          series.perceivedExertion > 0 ? series.perceivedExertion.toString() : '-',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SizedBox(),
                  if (showRPEAndCheckbox)
                    Expanded(
                      child: Center(
                        child: Checkbox(
                          value: series.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              if (value == true &&
                                  widget.isExecution &&
                                  widget.onAutofillSeries != null) {
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
