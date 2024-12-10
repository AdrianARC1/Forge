// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'auth/login_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import './widgets/base_scaffold.dart';
import '../styles/global_styles.dart';
import 'widgets/history_list_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool showAllRecords = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.username == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(backgroundColor: GlobalStyles.backgroundColor);
    }

    int totalWorkouts = appState.completedRoutines.length;
    int totalVolume = appState.completedRoutines.fold<int>(0, (int sum, routine) {
      return sum + (routine.totalVolume);
    });

    List<Map<String, dynamic>> personalRecords = appState.getPersonalRecords();
    List<Map<String, dynamic>> top5Records = personalRecords.take(5).toList();
    List<Map<String, dynamic>> remainingRecords = personalRecords.length > 5
        ? personalRecords.skip(5).toList()
        : [];

    return BaseScaffold(
      backgroundColor: GlobalStyles.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Perfil', style: GlobalStyles.insideAppTitleStyle),
        leading: IconButton(
          icon: const Icon(Icons.download, color: GlobalStyles.textColor),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidad en desarrollo')),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: GlobalStyles.textColor,
                size: 24.0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              tooltip: 'Configuración',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(top: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        await appState.updateProfileImage(pickedFile.path);
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      backgroundImage: appState.profileImagePath != null
                          ? FileImage(File(appState.profileImagePath!))
                          : const AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.username ?? 'Usuario',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rutinas completadas: $totalWorkouts',
                          style: const TextStyle(color: GlobalStyles.textColorWithOpacity),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: GlobalStyles.textColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Volumen total
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: GlobalStyles.textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Volumen total acumulado: $totalVolume kg',
                      style: const TextStyle(color: GlobalStyles.textColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gráficos
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text('Progreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              height: 350,
              child: const DataGraphs(),
            ),

            const SizedBox(height: 24),

            // Mejores marcas personales
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                'Mejores Marcas Personales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalStyles.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8.0),
              child: top5Records.isEmpty && remainingRecords.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay marcas personales registradas.',
                        style: TextStyle(
                          color: GlobalStyles.textColorWithOpacity,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        ...top5Records.map((record) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: record['gifUrl'] != null
                                  ? NetworkImage(record['gifUrl'])
                                  : null,
                              child: record['gifUrl'] == null
                                  ? const Icon(Icons.image_not_supported)
                                  : null,
                            ),
                            title: Text(
                              record['exerciseName'],
                              style: const TextStyle(color: GlobalStyles.textColor),
                            ),
                            subtitle: Text(
                              '${record['maxWeight']} kg x ${record['maxReps']} reps',
                              style: const TextStyle(color: GlobalStyles.textColorWithOpacity),
                            ),
                          );
                        }),
                        if (remainingRecords.isNotEmpty && !showAllRecords)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showAllRecords = true;
                              });
                            },
                            child: const Text(
                              'Ver más ejercicios',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        if (showAllRecords)
                          ...remainingRecords.map((record) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: record['gifUrl'] != null
                                    ? NetworkImage(record['gifUrl'])
                                    : null,
                                child: record['gifUrl'] == null
                                    ? const Icon(Icons.image_not_supported)
                                    : null,
                              ),
                              title: Text(
                                record['exerciseName'],
                                style: const TextStyle(color: GlobalStyles.textColor),
                              ),
                              subtitle: Text(
                                '${record['maxWeight']} kg x ${record['maxReps']} reps',
                                style: const TextStyle(color: GlobalStyles.textColorWithOpacity),
                              ),
                            );
                          }),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Historial
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text('Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            ),
            const SizedBox(height: 8),
            const HistoryListWidget(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class DataGraphs extends StatefulWidget {
  const DataGraphs({super.key});

  @override
  State<DataGraphs> createState() => _DataGraphsState();
}

class _DataGraphsState extends State<DataGraphs> {
  String selectedData = 'Duración';
  String selectedTimeframe = 'Semana';

  List<Map<String, dynamic>> groupedData = [];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    groupedData = _getGroupedData(appState);

    List<BarChartGroupData> barData = getBarChartData();
    double? maxY = _getMaxY(barData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              groupsSpace: 12,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => leftTitleWidgets(value, meta),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => bottomTitleWidgets(value, meta),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: _calculateInterval(maxY),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
                drawVerticalLine: false,
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 4,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    // Mostrar un decimal para todo, así para grandes números se ve algo
                    return BarTooltipItem(
                      '${group.x}: ${rod.toY.toStringAsFixed(1)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              barGroups: barData,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              DataButton(
                label: 'Duración',
                selected: selectedData == 'Duración',
                onTap: () {
                  setState(() {
                    selectedData = 'Duración';
                  });
                },
              ),
              DataButton(
                label: 'Volumen',
                selected: selectedData == 'Volumen',
                onTap: () {
                  setState(() {
                    selectedData = 'Volumen';
                  });
                },
              ),
              DataButton(
                label: 'RIR Medio',
                selected: selectedData == 'RIR Medio',
                onTap: () {
                  setState(() {
                    selectedData = 'RIR Medio';
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TimeframeButton(
                label: 'Semana',
                selected: selectedTimeframe == 'Semana',
                onTap: () {
                  setState(() {
                    selectedTimeframe = 'Semana';
                  });
                },
              ),
              TimeframeButton(
                label: 'Mes',
                selected: selectedTimeframe == 'Mes',
                onTap: () {
                  setState(() {
                    selectedTimeframe = 'Mes';
                  });
                },
              ),
              TimeframeButton(
                label: 'Año',
                selected: selectedTimeframe == 'Año',
                onTap: () {
                  setState(() {
                    selectedTimeframe = 'Año';
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  double? _getMaxY(List<BarChartGroupData> barData) {
    if (barData.isEmpty) return 0;
    double maxVal = 0;
    for (var group in barData) {
      for (var rod in group.barRods) {
        if (rod.toY > maxVal) maxVal = rod.toY;
      }
    }
    return maxVal;
  }

  double _calculateInterval(double? maxY) {
    if (maxY == null || maxY <= 0) return 1;
    // 5 líneas aproximadas
    double interval = maxY / 5;
    if (interval < 1) {
      interval = double.parse(interval.toStringAsFixed(1));
      if (interval <= 0) interval = 0.1;
    }
    return interval;
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    double interval = _calculateInterval(meta.max);
    double ratio = value / interval;
    // Si el valor es cercano a un múltiplo del intervalo, lo mostramos
    if ((ratio - ratio.round()).abs() < 0.001) {
      // Mostrar decimales sólo si interval < 1
      String label = interval < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w300),
        ),
      );
    }
    return Container();
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < 0 || index >= groupedData.length) {
      return Container();
    }
    String text = groupedData[index]['key'];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w300),
      ),
    );
  }

  List<Map<String, dynamic>> _getGroupedData(AppState appState) {
    List<Routine> routines = appState.completedRoutines;
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (selectedTimeframe) {
      case 'Semana':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Mes':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Año':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    routines = routines.where((r) => r.dateCompleted != null && r.dateCompleted!.isAfter(startDate)).toList();
    routines.sort((a, b) => a.dateCompleted!.compareTo(b.dateCompleted!));

    Map<String, Map<String, dynamic>> aggregated = {};

    for (var r in routines) {
      DateTime d = r.dateCompleted!;
      String key;
      if (selectedTimeframe == 'Año') {
        key = '${d.month}/${d.year}';
      } else {
        key = '${d.day}/${d.month}';
      }

      if (!aggregated.containsKey(key)) {
        aggregated[key] = {
          'key': key,
          'duracion': 0.0,
          'volumen': 0.0,
          'rir': [],
        };
      }

      aggregated[key]!['duracion'] += r.duration.inMinutes;
      aggregated[key]!['volumen'] += r.totalVolume;
      double routineRIR = _calculateAverageRIR(r);
      aggregated[key]!['rir'].add(routineRIR);
    }

    List<Map<String, dynamic>> result = [];
    aggregated.forEach((k, v) {
      List rirList = v['rir'];
      double avgRIR = 0;
      if (rirList.isNotEmpty) {
        avgRIR = rirList.reduce((a, b) => a + b) / rirList.length;
      }

      result.add({
        'key': v['key'],
        'duracion': v['duracion'],
        'volumen': v['volumen'],
        'rirMedio': avgRIR,
      });
    });

    return result;
  }

  double _calculateAverageRIR(Routine routine) {
    int totalRIR = 0;
    int count = 0;
    for (var exercise in routine.exercises) {
      for (var series in exercise.series) {
        totalRIR += series.perceivedExertion;
        count++;
      }
    }
    return count > 0 ? totalRIR / count : 0.0;
  }

  List<BarChartGroupData> getBarChartData() {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < groupedData.length; i++) {
      double yValue;
      switch (selectedData) {
        case 'Duración':
          yValue = groupedData[i]['duracion'];
          break;
        case 'Volumen':
          yValue = groupedData[i]['volumen'].toDouble();
          break;
        case 'RIR Medio':
          yValue = groupedData[i]['rirMedio'];
          break;
        default:
          yValue = 0;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yValue,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFAA76), Color(0xFFFF7E76)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }
}

class DataButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DataButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? GlobalStyles.backgroundButtonsColor : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}

class TimeframeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TimeframeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: selected ? GlobalStyles.backgroundButtonsColor : Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
