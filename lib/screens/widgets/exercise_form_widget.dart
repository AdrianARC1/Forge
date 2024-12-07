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
  final Map<String, dynamic>? maxRecord;
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

class _ExerciseFormWidgetState extends State<ExerciseFormWidget> with SingleTickerProviderStateMixin {
  Map<String, GlobalKey> seriesRowKeys = {};
  OverlayEntry? activeOverlay;
  Map<String, double> tempRPEValues = {};
  Map<String, double> originalRPEValues = {};
  String? activeSliderSeriesId;
  bool isNewRecord = false;
  late AnimationController _animationController;
  double currentMax1RM = 0.0;
  int currentMaxWeight = 0;
  int currentMaxReps = 0;

  @override
  void initState() {
    super.initState();
    for (var series in widget.exercise.series) {
      seriesRowKeys[series.id] = GlobalKey();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _initializeMaxRecord();
  }

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
        isNewRecord = false;
      });
    }
  }

  @override
  void dispose() {
    activeOverlay?.remove();
    _animationController.dispose();
    super.dispose();
  }

  void showRPEOverlay(BuildContext context, Series series) {
    activeOverlay?.remove();
    RenderBox renderBox =
        seriesRowKeys[series.id]!.currentContext!.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);
    Size size = renderBox.size;

    activeOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height + 10,
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
                      divisions: 9,
                      label: currentValue.round().toString(),
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
                      onChanged: (double newValue) {
                        setOverlayState(() {
                          tempRPEValues[series.id] = newValue;
                          series.perceivedExertion = newValue.round();
                        });
                        setState(() {});
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            activeOverlay?.remove();
                            activeOverlay = null;
                            setState(() {
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
                            activeOverlay?.remove();
                            activeOverlay = null;
                            setState(() {
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

    Overlay.of(context)!.insert(activeOverlay!);
  }

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

          _animationController.forward(from: 0).then((_) {
            _animationController.reverse();
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showRPEAndCheckbox = widget.isExecution;
    bool showEditOptions = widget.isExecution || widget.allowEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: widget.exercise.gifUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.exercise.gifUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.exercise.gifUrl == null
                    ? Icon(Icons.image_not_supported)
                    : null,
              ),
              SizedBox(width: 8),
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
                    if (widget.showMaxRecord)
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_animationController.value * 0.5),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    child: Center(
                      child: Text(
                        "SERIE",
                        style: GlobalStyles.subtitleStyle,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isExecution)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Container(
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
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    child: Center(
                      child: Text(
                        "KG",
                        style: GlobalStyles.subtitleStyle,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    child: Center(
                      child: Text(
                        "REPS",
                        style: GlobalStyles.subtitleStyle,
                      ),
                    ),
                  ),
                ),
              ),
              if (showRPEAndCheckbox)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Container(
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
              if (showRPEAndCheckbox)
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: SizedBox(),
                )
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
            double currentRPE = tempRPEValues[series.id]?.toDouble() ??
                series.perceivedExertion.toDouble();

            return DismissibleSeriesItem(
              series: series,
              onDelete: () => widget.onDeleteSeries?.call(seriesIndex),
              child: Container(
                decoration: BoxDecoration(
                  // Solo verde si isExecution es true
                  color: (series.isCompleted && widget.isExecution)
                      ? Color(0xFF008922)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  key: seriesRowKeys[series.id],
                  padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                      if (widget.isExecution)
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                if (widget.onAutofillSeries != null) {
                                  widget.onAutofillSeries!(series, markCompleted: false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                      Expanded(
                        flex: 2,
                        child: widget.isReadOnly
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: series.isCompleted
                                        ? Colors.transparent
                                        : GlobalStyles.inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: widget.weightControllers[series.id],
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
                                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    style: GlobalStyles.subtitleStyle,
                                    onChanged: (value) {
                                      setState(() {
                                        series.weight = int.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ),
                      ),
                      Expanded(
                        flex: 2,
                        child: widget.isReadOnly
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: series.isCompleted
                                        ? Colors.transparent
                                        : GlobalStyles.inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: widget.repsControllers[series.id],
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
                                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(8),
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
                      if (showRPEAndCheckbox)
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                      if (showRPEAndCheckbox)
                        Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                series.isCompleted = !series.isCompleted;
                                if (series.isCompleted) {
                                  if (widget.isExecution && widget.onAutofillSeries != null) {
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
                                      if (widget.isExecution && widget.onAutofillSeries != null) {
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
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalStyles.inputBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onAddSeries,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Introducir serie",
                  style: GlobalStyles.buttonTextStyle.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
