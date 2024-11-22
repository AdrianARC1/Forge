// lib/screens/widgets/exercise_form_widget.dart

import 'package:flutter/material.dart';
import 'package:forge/styles/global_styles.dart';
import '../../app_state.dart';
import '../widgets/dismissible_series_item.dart';

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
  final void Function(Series, {bool markCompleted})? onAutofillSeries;
  final Map<String, dynamic>? maxRecord; // Máximo histórico
  final bool allowEditing;
  final bool isReadOnly;
  final bool showMaxRecord;

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
    this.showMaxRecord = true,
  });

  @override
  _ExerciseFormWidgetState createState() => _ExerciseFormWidgetState();
}

class _ExerciseFormWidgetState extends State<ExerciseFormWidget>
    with SingleTickerProviderStateMixin {
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
    RenderBox renderBox =
        seriesRowKeys[series.id]!.currentContext!.findRenderObject() as RenderBox;
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
              borderRadius: BorderRadius.circular(12),
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
                    (series.perceivedExertion > 0
                        ? series.perceivedExertion.toDouble()
                        : 1.0);

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
                                series.perceivedExertion =
                                    originalRPEValues[series.id]!.round();
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
          _animationController.forward(from: 0).then((_) {
            _animationController.reverse(); // Revertir para volver al estado original
          });
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
        // Encabezado con nombre del ejercicio, máximo histórico y menú de opciones
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen del ejercicio
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(
                        'https://static.strengthlevel.com/images/exercises/bench-press/bench-press-800.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 8), // Espacio entre la imagen y el texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: GlobalStyles.subtitleStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.showMaxRecord) // Condicional para mostrar la fila del máximo histórico
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    1.0 + (_animationController.value * 0.5), // Animación
                                child: Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${currentMaxWeight}kg x ${currentMaxReps} reps',
                            style: GlobalStyles.subtitleStyle.copyWith(
                              fontSize: 14,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Máximo Histórico'),
                                  content: Text(
                                      'Este es tu mejor rendimiento registrado en este ejercicio.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Menú de opciones con ícono blanco
              if (showEditOptions)
                PopupMenuButton<String>(
                  offset: const Offset(0.0, 40.0),
                  icon: Icon(Icons.more_vert, color: Colors.white),
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
                ),
            ],
          ),
        ),
        // Cabecera de las columnas (sin fondo)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            children: [
              // SERIE
              Expanded(
                flex: 2, // Coincide con SERIE en las filas de entrada
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Center(
                      child: Text(
                        "SERIE",
                        style: GlobalStyles.subtitleStyle,
                      ),
                    ),
                  ),
                ),
              ),
              // ANTERIOR
              if (widget.isExecution)
                Expanded(
                  flex: 3, // Coincide con ANTERIOR en las filas de entrada
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Center(
                        child: Text(
                          "ANTERIOR",
                          style: GlobalStyles.subtitleStyle,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(),
              // KG
              Expanded(
                flex: 2, // Coincide con KG en las filas de entrada
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Center(
                      child: Text(
                        "KG",
                        style: GlobalStyles.subtitleStyle,
                      ),
                    ),
                  ),
                ),
              ),
              // REPS
              Expanded(
                flex: 2, // Coincide con REPS en las filas de entrada
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Center(
                      child: Text(
                        "REPS",
                        style: GlobalStyles.subtitleStyle,
                      ),
                    ),
                  ),
                ),
              ),
              // RPE
              if (showRPEAndCheckbox)
                Expanded(
                  flex: 2, // Incrementado a 2 para equilibrar RPE
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Center(
                        child: Text(
                          "RPE",
                          style: GlobalStyles.subtitleStyle,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(),
              // CHECKBOX
              if (showRPEAndCheckbox)
                Container(
                  width: 40, // Ajusta este valor según el tamaño del Checkbox
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: SizedBox(),
                )
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
            double currentRPE = tempRPEValues[series.id]?.toDouble() ??
                series.perceivedExertion.toDouble();

            return DismissibleSeriesItem(
              series: series,
              onDelete: () => widget.onDeleteSeries?.call(seriesIndex),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      series.isCompleted ? Color(0xFF008922) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  key: seriesRowKeys[series.id],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
                  child: Row(
                    children: [
                      // SERIE
                      Expanded(
                        flex: 2, // Mantener flex:2
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0), // Reducido vertical padding
                            decoration: BoxDecoration(
                              color: series.isCompleted
                                  ? Colors.transparent
                                  : GlobalStyles.inputBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "${seriesIndex + 1}",
                                style: GlobalStyles.subtitleStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ANTERIOR
                      if (widget.isExecution)
                        Expanded(
                          flex: 3, // Mantener flex:3
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                if (widget.onAutofillSeries != null) {
                                  widget.onAutofillSeries!(series,
                                      markCompleted: false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0), // Reducido vertical padding
                                decoration: BoxDecoration(
                                  color: series.isCompleted
                                      ? Colors.transparent
                                      : GlobalStyles.inputBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    "${series.previousWeight ?? '-'} kg x ${series.previousReps ?? '-'}",
                                    style: GlobalStyles.subtitleStyle
                                        .copyWith(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(),
                      // KG
                      Expanded(
                        flex: 2, // Mantener flex:2
                        child: widget.isReadOnly
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: series.isCompleted
                                        ? Colors.transparent
                                        : GlobalStyles.inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      series.weight.toString(),
                                      textAlign: TextAlign.center,
                                      style: GlobalStyles.subtitleStyle,
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: series.isCompleted
                                        ? Colors.transparent
                                        : GlobalStyles.inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller:
                                        widget.weightControllers[series.id],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: series.previousWeight != null
                                          ? "${series.previousWeight}"
                                          : 'KG',
                                      hintStyle: GlobalStyles.subtitleStyle.copyWith(
                                          color: GlobalStyles.placeholderColor),
                                      isDense: true,
                                      filled: true,
                                      fillColor: series.isCompleted
                                          ? Colors.transparent
                                          : GlobalStyles.inputBackgroundColor,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    style: GlobalStyles.subtitleStyle,
                                    onChanged: (value) {
                                      setState(() {
                                        series.weight =
                                            int.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ),
                      // REPS
                      Expanded(
                        flex: 2, // Mantener flex:2
                        child: widget.isReadOnly
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: series.isCompleted
                                        ? Colors.transparent
                                        : GlobalStyles.inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      series.reps.toString(),
                                      textAlign: TextAlign.center,
                                      style: GlobalStyles.subtitleStyle,
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: series.isCompleted
                                        ? Colors.transparent
                                        : GlobalStyles.inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller:
                                        widget.repsControllers[series.id],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: series.previousReps != null
                                          ? "${series.previousReps}"
                                          : 'Reps',
                                      hintStyle: GlobalStyles.subtitleStyle.copyWith(
                                          color: GlobalStyles.placeholderColor),
                                      isDense: true,
                                      filled: true,
                                      fillColor: series.isCompleted
                                          ? Colors.transparent
                                          : GlobalStyles.inputBackgroundColor,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    style: GlobalStyles.subtitleStyle,
                                    onChanged: (value) {
                                      setState(() {
                                        series.reps = int.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ),
                      // RPE
                      if (showRPEAndCheckbox)
                        Expanded(
                          flex: 2, // Incrementado a 2 para equilibrar RPE
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isActive) {
                                    activeOverlay?.remove();
                                    activeOverlay = null;
                                    tempRPEValues.remove(series.id);
                                    originalRPEValues.remove(series.id);
                                    activeSliderSeriesId = null;
                                  } else {
                                    activeSliderSeriesId = series.id;
                                    originalRPEValues[series.id] =
                                        series.perceivedExertion.toDouble();
                                    tempRPEValues[series.id] =
                                        series.perceivedExertion > 0
                                            ? series.perceivedExertion.toDouble()
                                            : 1.0;
                                    showRPEOverlay(context, series);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0), // Reducido vertical padding
                                decoration: BoxDecoration(
                                  color: series.isCompleted
                                      ? Colors.transparent
                                      : GlobalStyles.inputBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    series.perceivedExertion > 0
                                        ? series.perceivedExertion.toString()
                                        : '-',
                                    style: GlobalStyles.subtitleStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(),
                      // CHECKBOX
                      if (showRPEAndCheckbox)
                        Container(
                          width: 40, // Ajusta este valor según el tamaño del Checkbox
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                series.isCompleted = !series.isCompleted;
                                if (series.isCompleted) {
                                  if (widget.isExecution &&
                                      widget.onAutofillSeries != null) {
                                    widget.onAutofillSeries!(series);
                                  }
                                  _checkForNewRecord(series);
                                }
                              });
                            },
                            child: Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: series.isCompleted,
                                onChanged: (value) {
                                  setState(() {
                                    series.isCompleted = value ?? false;
                                    if (series.isCompleted) {
                                      if (widget.isExecution &&
                                          widget.onAutofillSeries != null) {
                                        widget.onAutofillSeries!(series);
                                      }
                                      _checkForNewRecord(series);
                                    }
                                  });
                                },
                                activeColor: Color(0xFF2D753F),
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Color(0xFF2D753F),
                                  width: 2.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                visualDensity: VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (!widget.isReadOnly)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 0.0, vertical: 8.0), // Sin padding izquierdo
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalStyles.inputBackgroundColor, // Color de fondo del botón
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bordes redondeados
                  ),
                ),
                onPressed: widget.onAddSeries,
                icon: Icon(Icons.add, color: Colors.white), // Ícono blanco
                label: Text(
                  "Introducir serie",
                  style: GlobalStyles.buttonTextStyle
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
