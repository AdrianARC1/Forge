// lib/screens/widgets/exercise_form_widget.dart

import 'package:flutter/material.dart';
import '../../app_state.dart';

class ExerciseFormWidget extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback? onAddSeries;
  final Function(int)? onDeleteSeries;
  final Map<String, TextEditingController> weightControllers;
  final Map<String, TextEditingController> repsControllers;
  final Map<String, TextEditingController> exertionControllers;
  final bool isExecution;
  final VoidCallback? onDeleteExercise;
  final Future<void> Function()? onReplaceExercise;
  final Function(Series)? onAutofillSeries;
  final Map<String, dynamic>? maxRecord; // Agregamos el parámetro maxRecord
  final bool allowEditing;
  final bool isReadOnly;

  ExerciseFormWidget({
    required this.exercise,
    this.onAddSeries,
    this.onDeleteSeries,
    required this.weightControllers,
    required this.repsControllers,
    required this.exertionControllers,
    this.isExecution = false,
    this.onDeleteExercise,
    this.onReplaceExercise,
    this.onAutofillSeries,
    this.maxRecord,
    this.allowEditing = false,
    this.isReadOnly = false,
  });

  @override
  _ExerciseFormWidgetState createState() => _ExerciseFormWidgetState();
}

class _ExerciseFormWidgetState extends State<ExerciseFormWidget> with SingleTickerProviderStateMixin {
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

  // Propiedades para manejar el nuevo récord
  bool isNewRecord = false;
  late AnimationController _animationController;
  double currentMax1RM = 0.0;
  int currentMaxWeight = 0;
  int currentMaxReps = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar los GlobalKeys para cada serie
    for (var series in widget.exercise.series) {
      seriesRowKeys[series.id] = GlobalKey();
    }

    // Inicializar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    // Inicializar los valores actuales del máximo histórico
    _initializeMaxRecord();
  }

  // Método para inicializar los valores del máximo histórico
  void _initializeMaxRecord() {
    if (widget.maxRecord != null) {
      currentMax1RM = widget.maxRecord!['max1RM'] as double;
      currentMaxWeight = widget.maxRecord!['maxWeight'] as int;
      currentMaxReps = widget.maxRecord!['maxReps'] as int;
    } else {
      currentMax1RM = 0.0;
      currentMaxWeight = 0;
      currentMaxReps = 0;
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.maxRecord != oldWidget.maxRecord) {
      setState(() {
        _initializeMaxRecord();
        isNewRecord = false; // Reiniciamos la animación del trofeo
      });
    }
  }

  @override
  void dispose() {
    // Asegurarse de eliminar cualquier OverlayEntry activo al destruir el widget
    activeOverlay?.remove();

    _animationController.dispose();

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

  // Método para verificar si hay un nuevo récord al marcar la serie como completada
  void _checkForNewRecord(Series series) {
    final weightController = widget.weightControllers[series.id];
    final repsController = widget.repsControllers[series.id];

    int weight = int.tryParse(weightController?.text ?? '') ?? 0;
    int reps = int.tryParse(repsController?.text ?? '') ?? 0;

    if (weight > 0 && reps > 0) {
      double estimated1RM = weight * (1 + reps / 30);

      if (estimated1RM > currentMax1RM) {
        setState(() {
          isNewRecord = true;
          currentMax1RM = estimated1RM;
          currentMaxWeight = weight;
          currentMaxReps = reps;

          // Iniciar la animación del trofeo
          _animationController.forward(from: 0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si mostrar el campo de RPE y la casilla de verificación
    bool showRPEAndCheckbox = widget.isExecution;

    // Determinar si mostrar las opciones de edición
    bool showEditOptions = widget.isExecution || widget.allowEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            widget.exercise.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          trailing: showEditOptions
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
                      if (widget.isExecution || widget.allowEditing)
                        PopupMenuItem(
                          value: 'replace',
                          child: Text('Reemplazar Ejercicio'),
                        ),
                    ];
                  },
                )
              : null,
        ),
        // Mostrar máximo histórico
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                '${currentMaxWeight}kg x ${currentMaxReps} reps',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  // Mostrar explicación
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Máximo Histórico'),
                      content: Text('Este es tu mejor rendimiento registrado en este ejercicio.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (isNewRecord)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Icon(
                      Icons.emoji_events,
                      color: Colors.amber.withOpacity(_animationController.value),
                      size: 24 + _animationController.value * 8,
                    );
                  },
                ),
            ],
          ),
        ),
        // Cabecera de las columnas
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
        // Series
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
                    child: widget.isReadOnly
                        ? Center(
                            child: Text(
                              series.weight.toString(),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: widget.weightControllers[series.id],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: series.previousWeight != null ? "${series.previousWeight} kg" : 'KG',
                                hintStyle: TextStyle(color: Colors.grey),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                series.weight = int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                  ),
                  Expanded(
                    child: widget.isReadOnly
                        ? Center(
                            child: Text(
                              series.reps.toString(),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: widget.repsControllers[series.id],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: series.previousReps != null ? "${series.previousReps} reps" : 'Reps',
                                hintStyle: TextStyle(color: Colors.grey),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                series.reps = int.tryParse(value) ?? 0;
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
                              if (value == true) {
                                series.isCompleted = true;

                                // Autorellenar datos si es ejecución y la función está disponible
                                if (widget.isExecution && widget.onAutofillSeries != null) {
                                  widget.onAutofillSeries!(series);
                                }

                                // Verificar si hay un nuevo récord al completar la serie
                                _checkForNewRecord(series);

                              } else {
                                series.isCompleted = false;
                              }
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
        if (!widget.isReadOnly)
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
