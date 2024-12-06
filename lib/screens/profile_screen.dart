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
import './widgets/app_bar_button.dart';
import '../styles/global_styles.dart';
import 'widgets/history_list_widget.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
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
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
      return Scaffold(backgroundColor: GlobalStyles.backgroundColor);
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
        title: Text('Perfil', style: GlobalStyles.insideAppTitleStyle),
        leading: IconButton(
          icon: Icon(Icons.download, color: GlobalStyles.textColor), // Icono de descarga
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Funcionalidad en desarrollo')),
            );
          },
        ),
        actions: [
          AppBarButton(
            text: 'Ajustes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            textColor: GlobalStyles.textColor,
            backgroundColor: Colors.transparent,
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
              padding: EdgeInsets.all(16.0),
              margin: EdgeInsets.only(top: 16.0),
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
                      backgroundImage: appState.profileImagePath != null
                          ? FileImage(File(appState.profileImagePath!))
                          : AssetImage('assets/default_profile.jpg') as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.username ?? 'Usuario',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GlobalStyles.textColor),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Rutinas completadas: $totalWorkouts',
                          style: TextStyle(color: GlobalStyles.textColorWithOpacity),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: GlobalStyles.textColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
            // Volumen total
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: GlobalStyles.textColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Volumen total acumulado: $totalVolume kg',
                      style: TextStyle(color: GlobalStyles.textColor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Gráficos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Progreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16.0),
              height: 350,
              child: DataGraphs(),
            ),

            SizedBox(height: 24),

            // Mejores marcas personales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Mejores Marcas Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: GlobalStyles.inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ...top5Records.map((record) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: record['gifUrl'] != null
                            ? NetworkImage(record['gifUrl'])
                            : null,
                        child: record['gifUrl'] == null ? Icon(Icons.image_not_supported) : null,
                      ),
                      title: Text(record['exerciseName'], style: TextStyle(color: GlobalStyles.textColor)),
                      subtitle: Text('${record['maxWeight']} kg x ${record['maxReps']} reps', style: TextStyle(color: GlobalStyles.textColorWithOpacity)),
                    );
                  }).toList(),
                  if (remainingRecords.isNotEmpty && !showAllRecords)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showAllRecords = true;
                        });
                      },
                      child: Text('Ver más ejercicios', style: TextStyle(color: Colors.blue)),
                    ),
                  if (showAllRecords)
                    ...remainingRecords.map((record) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: record['gifUrl'] != null
                              ? NetworkImage(record['gifUrl'])
                              : null,
                          child: record['gifUrl'] == null ? Icon(Icons.image_not_supported) : null,
                        ),
                        title: Text(record['exerciseName'], style: TextStyle(color: GlobalStyles.textColor)),
                        subtitle: Text('${record['maxWeight']} kg x ${record['maxReps']} reps', style: TextStyle(color: GlobalStyles.textColorWithOpacity)),
                      );
                    }).toList(),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Historial
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GlobalStyles.textColor)),
            ),
            SizedBox(height: 8),
            HistoryListWidget(),

            SizedBox(height: 24),

            // Botón de cerrar sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalStyles.backgroundButtonsColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    await appState.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Text('Cerrar Sesión', style: GlobalStyles.buttonTextStyle),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// DataGraphs, DataButton, TimeframeButton son iguales al ejemplo anterior
// Se asume que ya fueron implementados con intervalos inteligentes y agrupamiento por día/mes/año.
// Puedes usar la última versión que te pasé de DataGraphs.

class DataGraphs extends StatefulWidget {
  @override
  _DataGraphsState createState() => _DataGraphsState();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: barData,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: leftTitleWidgets,
                    reservedSize: 40
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: bottomTitleWidgets,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
            ),
          ),
        ),
        SizedBox(height: 16),
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
        SizedBox(height: 16),
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
          yValue = groupedData[i]['volumen'];
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
              color: Color(0xFFFFAA76),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (meta.max == null || meta.min == null) return Container();
    double interval = _calculateInterval(meta.max);
    if (value % interval == 0) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          value.toInt().toString(),
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
    return Container();
  }

  double _calculateInterval(double? maxY) {
    if (maxY == null || maxY == 0) return 1;
    double maxVal = maxY;
    int magnitude = (maxVal / 10).ceil();
    if (magnitude < 5) {
      return 5.0;
    } else if (magnitude < 10) {
      return 10.0;
    } else if (magnitude < 20) {
      return 20.0;
    } else if (magnitude < 50) {
      return 25.0;
    } else if (magnitude < 100) {
      return 50.0;
    } else if (magnitude < 200) {
      return 100.0;
    } else {
      return 200.0;
    }
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
        style: TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }
}

class DataButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DataButton({
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
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white)),
      ),
    );
  }
}

class TimeframeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TimeframeButton({
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
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
